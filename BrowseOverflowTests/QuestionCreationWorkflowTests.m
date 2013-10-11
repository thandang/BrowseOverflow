//
//  StackOverflowManagerTests.m
//  BrowseOverflow
//
//  Created by Graham J Lee on 14/03/2011.
//  Copyright 2011 Fuzzy Aliens Ltd. All rights reserved.
//

#import "QuestionCreationWorkflowTests.h"
#import "StackOverflowManager.h"
#import "MockStackOverflowManagerDelegate.h"
#import "MockStackOverflowCommunicator.h"
#import "FakeQuestionBuilder.h"
#import "Topic.h"
#import "Question.h"

@implementation QuestionCreationWorkflowTests
{
@private
    StackOverflowManager *mgr;
    MockStackOverflowManagerDelegate *delegate;
    FakeQuestionBuilder *questionBuilder;
    MockStackOverflowCommunicator *communicator;
    MockStackOverflowCommunicator *bodyCommunicator;
    Question *questionToFetch;
    NSError *underlyingError;
    NSArray *questionArray;
}

- (void)setUp {
    mgr = [[StackOverflowManager alloc] init];
    delegate = [[MockStackOverflowManagerDelegate alloc] init];
    mgr.delegate = delegate;
    underlyingError = [NSError errorWithDomain: @"Test domain" code: 0 userInfo: nil];
    questionBuilder = [[FakeQuestionBuilder alloc] init];
    questionBuilder.arrayToReturn = nil;
    mgr.questionBuilder = questionBuilder;
    questionToFetch = [[Question alloc] init];
    questionToFetch.questionID = 1234;
    questionArray = [NSArray arrayWithObject: questionToFetch];
    communicator = [[MockStackOverflowCommunicator alloc] init];
    mgr.communicator = communicator;
    bodyCommunicator = [[MockStackOverflowCommunicator alloc] init];
    mgr.bodyCommunicator = bodyCommunicator;
}

- (void)tearDown {
    mgr = nil;
    delegate = nil;
    questionBuilder = nil;
    questionToFetch = nil;
    questionArray = nil;
    communicator = nil;
    bodyCommunicator = nil;
    underlyingError = nil;
}

- (void)testNonConformingObjectCannotBeDelegate {
    STAssertThrows(mgr.delegate = (id <StackOverflowManagerDelegate>)[NSNull null], @"NSNull doesn't conform to the delegate protocol");
}

- (void)testConformingObjectCanBeDelegate {
    STAssertNoThrow(mgr.delegate = delegate, @"Object conforming to the delegate protocol can be delegate");
}

- (void)testManagerAcceptsNilAsADelegate {
    STAssertNoThrow(mgr.delegate = nil, @"It should be acceptable to use nil as an object's delegate");
}

- (void)testAskingForQuestionsMeansRequestingData {
    Topic *topic = [[Topic alloc] initWithName: @"iPhone" tag: @"iphone"];
    [mgr fetchQuestionsOnTopic: topic];
    STAssertTrue([communicator wasAskedToFetchQuestions], @"The communicator should need to fetch data.");
}

- (void)testErrorReturnedToDelegateIsNotErrorNotifiedByCommunicator {
    [mgr searchingForQuestionsFailedWithError: underlyingError];
    STAssertFalse(underlyingError == [delegate fetchError], @"Error should be at the correct level of abstraction");
}

- (void)testErrorReturnedToDelegateDocumentsUnderlyingError {
    [mgr searchingForQuestionsFailedWithError: underlyingError];
    STAssertEqualObjects([[[delegate fetchError] userInfo] objectForKey: NSUnderlyingErrorKey], underlyingError, @"The underlying error should be available to client code");
}

- (void)testQuestionJSONIsPassedToQuestionBuilder {
    [mgr receivedQuestionsJSON: @"Fake JSON"];
    STAssertEqualObjects(questionBuilder.JSON, @"Fake JSON", @"Downloaded JSON is sent to the builder");
}

- (void)testDelegateNotifiedOfErrorWhenQuestionBuilderFails {
    questionBuilder.errorToSet = underlyingError;
    [mgr receivedQuestionsJSON: @"Fake JSON"];
    STAssertNotNil([[[delegate fetchError] userInfo] objectForKey: NSUnderlyingErrorKey], @"The delegate should have found out about the error");
}

- (void)testDelegateNotToldAboutErrorWhenQuestionsReceived {
    questionBuilder.arrayToReturn = questionArray;
    [mgr receivedQuestionsJSON: @"Fake JSON"];
    STAssertNil([delegate fetchError], @"No error should be received on success");
}

- (void)testDelegateReceivesTheQuestionsDiscoveredByManager {
    questionBuilder.arrayToReturn = questionArray;
    [mgr receivedQuestionsJSON: @"Fake JSON"];
    STAssertEqualObjects([delegate fetchedQuestions], questionArray, @"The manager should have sent its questions to the delegate");
}

- (void)testEmptyArrayIsPassedToDelegate {
    questionBuilder.arrayToReturn = [NSArray array];
    [mgr receivedQuestionsJSON: @"Fake JSON"];
    STAssertEqualObjects([delegate fetchedQuestions], [NSArray array], @"Returning an empty array is not an error");
}

- (void)testAskingForQuestionBodyMeansRequestingData {
    [mgr fetchBodyForQuestion: questionToFetch];
    STAssertTrue([bodyCommunicator wasAskedToFetchBody], @"The communicator should need to retrieve data for the question body");
}

- (void)testDelegateNotifiedOfFailureToFetchQuestion {
    [mgr fetchingQuestionBodyFailedWithError: underlyingError];
    STAssertNotNil([[[delegate fetchError] userInfo] objectForKey: NSUnderlyingErrorKey], @"Delegate should have found out about this error");
}

- (void)testManagerPassesRetrievedQuestionBodyToQuestionBuilder {
    [mgr receivedQuestionBodyJSON: @"Fake JSON"];
    STAssertEqualObjects(questionBuilder.JSON, @"Fake JSON", @"Successfully-retrieved data should be passed to the builder");
}

- (void)testManagerPassesQuestionItWasSentToQuestionBuilderForFillingIn {
    [mgr fetchBodyForQuestion: questionToFetch];
    [mgr receivedQuestionBodyJSON: @"Fake JSON"];
    STAssertEqualObjects(questionBuilder.questionToFill, questionToFetch, @"The question should have been passed to the builder");
}

- (void)testManagerNotifiesDelegateWhenQuestionBodyIsReceived {
    [mgr fetchBodyForQuestion: questionToFetch];
    [mgr receivedQuestionBodyJSON: @"Fake JSON"];
    STAssertEqualObjects(delegate.bodyQuestion, questionToFetch, @"Update delegate when question body filled");
}

@end
