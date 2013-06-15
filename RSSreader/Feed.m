//
//  Feed.m
//  RSSreader
//
//  Created by Ayodeji Osokoya on 5/23/13.
//  Copyright (c) 2013 inspireology. All rights reserved.
//

#import "Feed.h"
@interface Feed()
@property (nonatomic, strong) NSMutableDictionary *temporaryItem;
@property (nonatomic, strong) NSMutableString *temporaryPostTitle;
@property (nonatomic, strong) NSMutableString *temporaryLink;
@property (nonatomic, strong) NSMutableString *temporaryDescription;
@property (nonatomic, strong) NSMutableString *temporaryPubdate;
@property (nonatomic, strong) NSMutableString *temporaryEnclosure;
@property (nonatomic, strong) NSMutableString *temporaryGuid;
@property (nonatomic, strong) NSString *parentElement;

@property (nonatomic, strong) NSXMLParser *parser;//parser is the object that will download and parse the RSS XML files
@property (nonatomic, strong) NSString *element;
@end

@implementation Feed
@synthesize isFollowed = _isFollowed;

- (void) setIsFollowed:(BOOL)isFollowed{
    if (isFollowed) {//if this is a feed we are gonna follow. Enable its parser and parse the feed.
        _isFollowed = YES;
        [self.parser setDelegate:self];
        [self.parser setShouldResolveExternalEntities:NO];
        [self.parser parse];
    } else {
        self.parser = nil;
        self.temporaryPostTitle = nil;
        self.temporaryLink = nil;
        self.temporaryDescription = nil;
        self.temporaryPubdate = nil;
        self.temporaryEnclosure = nil;
        self.temporaryGuid = nil;
        self.parentElement = nil;
    }
}

- (Feed *) initWithURL:(NSString *)feedURL isFollowed:(BOOL)isFollowed{
    self = [self initWithURL:feedURL withTitle:nil isFollowed:isFollowed];
    return self;
}

- (Feed *) initWithURL:(NSString *)feedURL withTitle:(NSString *)title isFollowed:(BOOL)isFollowed{//designated initializer
    if(self = [super init]) {
        self.link = [feedURL copy];
        //Allocate a Feed
        //set iself as a delegate
        self.title = [title mutableCopy];//this ought to replace the assigned title from the feed with the new title
        self.isFollowed = isFollowed;
    }
    return self;
}
- (void) refresh {
    [self.parser parse];
    //we could use NSNotification Center to update the view once this is done
}

- (NSMutableArray *) items{
    if(!_items) _items = [[NSMutableArray alloc] init];
    return _items;
}

- (NSXMLParser *) parser{
    if(!_parser) _parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:self.link]];
    return _parser;
}

- (void) parserDidStartDocument:(NSXMLParser *)parser{
}

#pragma mark - NSXMLParserDelegate implemenatation
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    self.element = elementName;
    
    if ([self.element isEqualToString:@"channel"]) {
        self.parentElement = @"channel";
        self.title = [[NSMutableString alloc] init];
    }
    else if ([self.element isEqualToString:@"item"]) {
        self.parentElement = @"item";
        self.temporaryItem  = [[NSMutableDictionary alloc] init];
        self.temporaryPostTitle   = [[NSMutableString alloc] init];
        self.temporaryLink    = [[NSMutableString alloc] init];
        self.temporaryDescription = [[NSMutableString alloc] init];
        self.temporaryPubdate = [[NSMutableString alloc] init];
        self.temporaryGuid = [[NSMutableString alloc] init];
        self.temporaryEnclosure = [[NSMutableString alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {//presents all of the chars of the current element
    if([self.parentElement isEqualToString:@"item"]){
        string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        if ([self.element isEqualToString:@"title"]) {
            [self.temporaryPostTitle appendString:string];
        } else if ([self.element isEqualToString:@"link"]) {
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            [self.temporaryLink appendString:string];//fixes accidental spaces in the feed URL
        } else if ([self.element isEqualToString:@"guid"]) {
            [self.temporaryGuid appendString:string];
        } else if ([self.element isEqualToString:@"description"]) {
            [self.temporaryDescription appendString:string];
        } else if ([self.element isEqualToString:@"pubDate"]) {
            [self.temporaryPubdate appendString:string];
        } else if ([self.element isEqualToString:@"enclosure"]) {
            [self.temporaryEnclosure appendString:string];
        }
    } else if ([self.parentElement isEqualToString:@"channel"]){
        if ([self.element isEqualToString:@"title"]) {
            if (![self.title length]) {
                self.title = [[NSMutableString alloc] init];
                [self.title appendString:string];//prevent overwriting of the feed title if one is set manually
                NSLog(@"Appended Title %@", self.title);
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"item"]) {
        [self.temporaryItem setObject:self.temporaryPostTitle forKey:@"title"];
        [self.temporaryItem setObject:self.temporaryLink forKey:@"link"];
        [self.temporaryItem setObject:self.temporaryDescription forKey:@"description"];
        [self.temporaryItem setObject:self.temporaryPubdate forKey:@"pubdate"];
        [self.temporaryItem setObject:self.link forKey:@"itemFeed"];
        [self.items addObject:[self.temporaryItem copy]];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
}

@end