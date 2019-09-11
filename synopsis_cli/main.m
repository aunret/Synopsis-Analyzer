//
//	main.m
//	synopsis_cli
//
//	Created by testAdmin on 9/10/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynopsisJobObject.h"




void usage()	{
	fprintf(stdout,"USAGE:\n");
	fprintf(stdout,"\tsynopsis_cli <json string describing an object with the job details>\n");
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		//	make sure the # of args is correct
		NSArray				*args = [[NSProcessInfo processInfo] arguments];
		if ([args count] != 2)	{
			fprintf(stdout,"ERR: must have exactly one arg\n");
			//NSString			*tmpString = [args description];
			//fprintf(stdout,"args were %s\n",[tmpString UTF8String]);
			usage();
			return 1;
		}
		
		//	make sure the passed arg is a valid JSON object
		NSError				*nsErr = nil;
		NSDictionary		*tmpDict = [NSJSONSerialization JSONObjectWithData:[args[1] dataUsingEncoding:NSUTF8StringEncoding] options:nil error:&nsErr];
		if (tmpDict == nil || nsErr != nil)	{
			fprintf(stdout, "ERR: couldn't parse JSON string");
			if (nsErr != nil)
				fprintf(stdout, ": %s", [[nsErr localizedDescription] UTF8String]);
			fprintf(stdout,"\n");
			return 2;
		}
		//	make sure that the JSON object is of the correct type
		if (![tmpDict isKindOfClass:[NSDictionary class]])	{
			fprintf(stdout, "ERR: JSON string must describe a JSON object\n");
			return 3;
		}
		
		
		//	make a dispatch group that we'll enter before starting, and leave upon completion of the job (prevent the task from exiting prematurely)
		dispatch_group_t		completionGroup = dispatch_group_create();
		dispatch_group_enter(completionGroup);
		
		//	make the job object
		SynopsisJobObject			*job = [SynopsisJobObject
			createWithJobJSONString:args[1]
			completionBlock:^(SynopsisJobObject *theJob)	{
				dispatch_group_leave(completionGroup);
			}];
		//	start the job...
		[job start];
		
		//	wait for the dispatch group to be notified before we return
		dispatch_group_wait(completionGroup, DISPATCH_TIME_FOREVER);
		
		//	if there weren't any errors, just return immediately
		if ([job jobStatus] == JOStatus_Complete)	{
			fprintf(stdout, "JOB COMPLETE, took %0.2f seconds\n",[job jobTimeElapsed]);
			return 0;
		}
		
		//	if i'm here, there was some kind of error- print out some information about it
		NSString		*statusString = [SynopsisJobObject stringForStatus:[job jobStatus]];
		NSString		*errTypeString = [SynopsisJobObject stringForErrorType:[job jobErr]];
		NSString		*errString = [job jobErrString];
		fprintf(stderr, "status is %s\n",[statusString UTF8String]);
		if ([job jobStatus] == JOStatus_Err)	{
			fprintf(stderr, "err type is %s\n",[errTypeString UTF8String]);
			fprintf(stderr, "err detail is %s\n",[errString UTF8String]);
		}
		return 4;
	}
	return 0;
}
