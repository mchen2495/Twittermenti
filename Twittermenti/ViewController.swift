//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2019.
//  Copyright © 2019 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let TweetCount = 100
    
    let sentimentClassifier = TweetSentimentClassifier()
    
    //api key was gotten from when we set up our app in twitter
    let swifter = Swifter(consumerKey: apiKey, consumerSecret: apiSecret)

    override func viewDidLoad() {
        super.viewDidLoad()
        //app behave as if light mode is on
        overrideUserInterfaceStyle = .light
        
        //        let prediction = try! sentimentClassifier.prediction(text: "@_____ is a terrible company!")
        //        print(prediction.label)
        
    }

    @IBAction func predictPressed(_ sender: Any) {
        
        fetchTweets()
    
    }
    
    
    
    func fetchTweets() {
        //don't want to perform twitter api call if the searchtext is empty
        if let searchText = textField.text{
            
            //getting the full text of the tweet for up to 100 tweets
            swifter.searchTweet(using: searchText, lang: "en", count: TweetCount, tweetMode: .extended) { (results, meta) in
                //success
                
                //gets a array of the tweets
                if let amount = results.array?.count {
                    var tweets = [TweetSentimentClassifierInput]()
                    for i in 0..<amount {
                        if let tweet = results[i]["full_text"].string{
                            
                            /*handle if tweet was a retweet, get the full text if it was a retweet
                             if it is a retweet limit for full text is only 140 characters
                             */
                            if tweet.hasPrefix("RT"){
                                if let fullTweet = results[i]["retweeted_status"]["full_text"].string{
                                    let tweetForClassificationRT = TweetSentimentClassifierInput(text: fullTweet)
                                    print("\(i)-------------\(fullTweet)")
                                    tweets.append(tweetForClassificationRT)
                                }
                            }
                            else{
                                print("\(i)-------------\(tweet)")
                                let tweetForClassification = TweetSentimentClassifierInput(text: tweet)
                                tweets.append(tweetForClassification)
                            }
                        }
                    }
                    self.makePredition(with: tweets)
                }
            } failure: { (error) in
                print("There was a error with the Twitter api request, \(error.localizedDescription)")
            }
        }
    }
    
    func makePredition(with tweets: [TweetSentimentClassifierInput]) {
        
        //batch process all of the tweets into our classifier
        do {
            let predictions  = try self.sentimentClassifier.predictions(inputs: tweets)
            
            var sentimentScore = 0
            
            for pred in predictions{
                //print(pred.label)
                
                let sentiment = pred.label
                
                if sentiment == "Pos" {
                    sentimentScore += 1
                }
                else if sentiment == "Neg"{
                    sentimentScore -= 1
                }
            }
            
            updateUI(with: sentimentScore)
            
        } catch {
            print("Error performing classification on tweets, \(error.localizedDescription)")
        }

    }
    
    func updateUI(with sentimentScore: Int){
        
        if sentimentScore > 20 {
            self.sentimentLabel.text = "😍"   //control command space for emoji selections
        }
        else if sentimentScore > 10 {
            self.sentimentLabel.text = "😀"
        }
        else if sentimentScore > 0 {
            self.sentimentLabel.text = "🙂"
        }
        else if sentimentScore == 0 {
            self.sentimentLabel.text = "😐"
        }
        else if sentimentScore > -10 {
            self.sentimentLabel.text = "😕"
        }
        else if sentimentScore > -20 {
            self.sentimentLabel.text = "😡"
        }
        else{
            self.sentimentLabel.text = "🤮"
        }
        
        print(sentimentScore)
        
    }
}


//MARK: -
/*
 refer to https://developer.twitter.com/en/docs/twitter-api/v1/tweets/search/api-reference/get-search-tweets
 for how response from api call looks like
 
 playground code to create model from csv dataset
 
 import Cocoa
 import CreateML

 let data = try MLDataTable(contentsOf: URL(fileURLWithPath: ".../Downloads/twitter-sanders-apple3.csv"))

 /*split data set into 80 percent training and 20 percent testing data. Seed is kind of id of random number
  generator. If in the future you want that same random split of 80 and 20% use the same seed
  */
 let(trainingData, testingData) = data.randomSplit(by: 0.8, seed: 5)

 //get text and label column from csv file
 let sentimentClassifier = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "class")

 let evaluationMetrics = sentimentClassifier.evaluation(on: testingData, textColumn: "text", labelColumn: "class")

 // 1 minus fraction of sample that were incorrectly label (getting the accurracy)
 let evaluationAccuray = (1.0 - evaluationMetrics.classificationError) * 100

 let metadata = MLModelMetadata(author: "Michael Chen", shortDescription: "A model trained to classify sentiment on Tweets", version: "1.0")

 //where you want the model to be saved at and what name you want to give the file
 try sentimentClassifier.write(to: URL(fileURLWithPath: "/Users/michaelchen/Downloads/TweetSentimentClassifier.mlmodel"))

 try sentimentClassifier.prediction(from: "I just found the best restaurant ever, and it's @DuckandWaffle")

 try sentimentClassifier.prediction(from: "I think @CocaCola ads are just ok.")
 
 
 
 */
