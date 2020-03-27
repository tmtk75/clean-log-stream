package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/aws/external"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatchlogs"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var Commit string

const (
	keyGroupName     = "log-group-name"
	keyLimit         = "limit"
	keyLastEventTime = "last-event-time"
	keyWait          = "wait"
)

func init() {
	f := RootCmd.PersistentFlags()

	f.String(keyGroupName, "", "Log group name to delete its stremas.")
	f.Int64(keyLimit, 50, "Limit to describe log stream.")
	f.Duration(keyLastEventTime, time.Hour*24*365, "Last event time to keep.")
	f.Duration(keyWait, time.Millisecond*100, "Time to wait for next deletion.")

	opts := []struct {
		key string
		env string
	}{
		{key: keyGroupName, env: "LOG_GROUP_NAME"},
		{key: keyLimit, env: "LIMIT"},
		{key: keyLastEventTime, env: "LAST_EVENT_TIME"},
		{key: keyWait, env: "WAIT"},
	}
	for _, e := range opts {
		viper.BindPFlag(e.key, f.Lookup(e.key))
		viper.BindEnv(e.key, e.env)
	}
}

var RootCmd = &cobra.Command{
	Use: "clean-log-stream",
	Example: `  AWS_PROFILE=your-profile AWS_DEFAULT_PROFILE=ap-northeast-1 \
  clean-log-stream \
    --log-group-name /ecs/my-task \
    --last-event-time 72h`,
	Run: func(cmd *cobra.Command, args []string) {
		Start()
	},
}

func main() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
}

func Start() {
	log.Printf("Commit: %v", Commit)

	var (
		//limit         = viper.GetInt64(keyLimit)
		groupName     = viper.GetString(keyGroupName)
		lastEventTime = viper.GetDuration(keyLastEventTime)
		sleep         = viper.GetDuration(keyWait)
	)

	cfg, err := external.LoadDefaultAWSConfig()
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	svc := cloudwatchlogs.New(cfg)
	var nextToken *string
	now := time.Now()
	count := 0
END:
	for {
		input := &cloudwatchlogs.DescribeLogStreamsInput{
			LogGroupName: aws.String(groupName),
			Descending:   aws.Bool(false),
			//Limit:        aws.Int64(limit),
			OrderBy:   cloudwatchlogs.OrderByLastEventTime,
			NextToken: nextToken,
		}
		out, err := svc.DescribeLogStreamsRequest(input).Send(context.Background())

		if err != nil {
			log.Fatalf("%v %v", err, input)
		}

		log.Printf("found %v streams.", len(out.LogStreams))

		for _, s := range out.LogStreams {
			ts := time.Unix(*s.LastEventTimestamp/1000, 0)
			d := now.Sub(ts) - lastEventTime

			if d <= 0 {
				log.Printf("stop due to %v", d)
				break END
			}

			_, err := svc.DeleteLogStreamRequest(&cloudwatchlogs.DeleteLogStreamInput{
				LogGroupName:  aws.String(groupName),
				LogStreamName: s.LogStreamName,
			}).Send(context.Background())
			time.Sleep(sleep)

			if err != nil {
				log.Printf("failed to delete. %v", err)
			} else {
				count++
			}
		}

		if out.NextToken == nil {
			log.Printf("no next stream.")
			break END
		}

		if *out.NextToken != "" {
			nextToken = out.NextToken
			log.Printf("deleted %v streams.", len(out.LogStreams))
		}
	}

	pl := ""
	if count > 1 {
		pl = "s"
	}
	log.Printf("finished to delete %v stream%s.", count, pl)
}
