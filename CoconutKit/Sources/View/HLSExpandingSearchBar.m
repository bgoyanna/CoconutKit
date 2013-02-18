//
//  HLSExpandingSearchBar.m
//  CoconutKit
//
//  Created by Samuel Défago on 11.06.12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "HLSExpandingSearchBar.h"

#import "NSArray+HLSExtensions.h"
#import "HLSFloat.h"
#import "HLSLogger.h"
#import "HLSViewAnimationStep.h"
#import "NSBundle+HLSExtensions.h"

static const CGFloat kSearchBarStandardHeight = 44.f;

@interface HLSExpandingSearchBar ()

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *searchButton;

@end

@implementation HLSExpandingSearchBar {
@private
    BOOL _layoutDone;
    BOOL _expanded;
    BOOL _animating;
}

#pragma mark Object creation and destruction

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self hlsExpandingSearchBarInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self hlsExpandingSearchBarInit];
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;

}

- (void)hlsExpandingSearchBarInit
{
    self.backgroundColor = [UIColor clearColor];
    
    // The embedded search bar has a fixed height. Apply the same constraint for self
    if (! floateq(CGRectGetHeight(self.frame), kSearchBarStandardHeight)) {
        HLSLoggerWarn(@"The search bar height is expected to be %.0f px. Fixed without changing the origin (but you should update your code)", kSearchBarStandardHeight);
        self.frame = CGRectMake(CGRectGetMinX(self.frame),
                                CGRectGetMinY(self.frame),
                                CGRectGetWidth(self.frame),
                                kSearchBarStandardHeight);
    }
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.f, 0.f, kSearchBarStandardHeight, kSearchBarStandardHeight)];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.searchBar.alpha = 0.f;
    self.searchBar.delegate = self;
    [self addSubview:self.searchBar];
    
    // Remove the search bar background
    self.searchBar.backgroundColor = [UIColor clearColor];
    UIView *backgroundView = [self.searchBar.subviews firstObject_hls];
    backgroundView.alpha = 0.f;
    
    self.searchButton = [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, kSearchBarStandardHeight, kSearchBarStandardHeight)];
    self.searchButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.searchButton setImage:[UIImage imageNamed:@"CoconutKit-resources.bundle/SearchFieldIcon.png"] forState:UIControlStateNormal];
    [self.searchButton addTarget:self 
                          action:@selector(toggleSearchBar:)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.searchButton];
}

#pragma mark Accessors and mutators

// TODO: When HLSRestrictedProtocolProxy is available, use it to restrict the UISearchBar interface to those methods,
//       and make interface and implementation simpler (can then get rid of the methods below)

- (NSString *)text
{
    if (! _expanded) {
        return nil;
    }
    
    return self.searchBar.text;
}

- (void)setText:(NSString *)text
{
    if (! _expanded) {
        HLSLoggerWarn(@"Cannot set the search bar text when closed");
        return;
    }
    
    self.searchBar.text = text;
}

- (void)setPrompt:(NSString *)prompt
{
    if (_prompt == prompt) {
        return;
    }
    
    _prompt = [prompt copy];
    
    if (_expanded) {
        self.searchBar.prompt = prompt;
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    if (_placeholder == placeholder) {
        return;
    }
    
    _placeholder = [placeholder copy];
    
    if (_expanded) {
        self.searchBar.placeholder = placeholder;
    }
}

- (UITextAutocapitalizationType)autocapitalizationType
{
    return self.searchBar.autocapitalizationType;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType
{
    self.searchBar.autocapitalizationType = autocapitalizationType;
}

- (UITextAutocorrectionType)autocorrectionType
{
    return self.searchBar.autocorrectionType;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)autocorrectionType
{
    self.searchBar.autocorrectionType = autocorrectionType;
}

- (UITextSpellCheckingType)spellCheckingType
{
    return self.searchBar.spellCheckingType;
}

- (void)setSpellCheckingType:(UITextSpellCheckingType)spellCheckingType
{
    self.searchBar.spellCheckingType = spellCheckingType;
}

- (UIKeyboardType)keyboardType
{
    return self.searchBar.keyboardType;
}

- (void)setKeyboardType:(UIKeyboardType)keyboardType
{
    self.searchBar.keyboardType = keyboardType;
}

- (void)setAlignment:(HLSExpandingSearchBarAlignment)alignment
{
    if (_layoutDone) {
        HLSLoggerWarn(@"The alignment cannot be changed once the search bar has been displayed");
        return;
    }
    
    _alignment = alignment;
}

#pragma mark Layout

- (void)layoutSubviews
{
    if (self.autoresizingMask & UIViewAutoresizingFlexibleHeight) {
        HLSLoggerWarn(@"The search bar cannot have a flexible height. Disabling the corresponding autoresizing mask flag");
        self.autoresizingMask &= ~UIViewAutoresizingFlexibleHeight;
    }
    
    // TODO: Factor out collapsed frame creation code
    if (! _animating) {
        if (self.alignment == HLSExpandingSearchBarAlignmentLeft || _expanded) {
            self.searchButton.frame = CGRectMake(0.f,
                                                 roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f),
                                                 kSearchBarStandardHeight,
                                                 kSearchBarStandardHeight);
        }
        else {
            self.searchButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - kSearchBarStandardHeight,
                                                 roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f),
                                                 kSearchBarStandardHeight,
                                                 kSearchBarStandardHeight);
        }
        
        if (_expanded) {
            self.searchBar.alpha = 1.f;
            self.searchBar.frame = CGRectMake(0.f,
                                              roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f),
                                              CGRectGetWidth(self.bounds),
                                              kSearchBarStandardHeight);
        }
        else {
            self.searchBar.frame = self.searchButton.frame;
        }
    }
    
    // Notify initial status
    if (! _layoutDone) {
        if (_expanded && [self.delegate respondsToSelector:@selector(expandingSearchBarDidExpand:animated:)]) {
            [self.delegate expandingSearchBarDidExpand:self animated:NO];
        }
        else if (! _expanded && [self.delegate respondsToSelector:@selector(expandingSearchBarDidCollapse:animated:)]) {
            [self.delegate expandingSearchBarDidCollapse:self animated:NO];
        }
        
        _layoutDone = YES;
    }
}

#pragma mark Animation

// We do not cache the animation: The source and target frames can vary depending on rotations. We
// therefore need a way to generate the animation easily when we need it
- (HLSAnimation *)expansionAnimation
{
    HLSViewAnimationStep *animationStep1 = [HLSViewAnimationStep animationStep];
    animationStep1.duration = 0.15;
    HLSViewAnimation *viewAnimation11 = [HLSViewAnimation animation];
    [viewAnimation11 addToAlpha:1.f];
    [animationStep1 addViewAnimation:viewAnimation11 forView:self.searchBar];
    
    HLSViewAnimationStep *animationStep2 = [HLSViewAnimationStep animationStep];
    animationStep2.duration = 0.25;
    
    CGRect collapsedFrame;
    if (self.alignment == HLSExpandingSearchBarAlignmentLeft) {
        collapsedFrame = CGRectMake(0.f, 
                                    roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f), 
                                    kSearchBarStandardHeight, 
                                    kSearchBarStandardHeight);
    }
    else {
        collapsedFrame = CGRectMake(CGRectGetWidth(self.bounds) - kSearchBarStandardHeight, 
                                    roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f), 
                                    kSearchBarStandardHeight, 
                                    kSearchBarStandardHeight);    
    }
    
    HLSViewAnimation *viewAnimation21 = [HLSViewAnimation animation];
    [viewAnimation21 transformFromRect:collapsedFrame
                                toRect:CGRectMake(0.f,
                                                  roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f),
                                                  CGRectGetWidth(self.bounds),
                                                  kSearchBarStandardHeight)];
    [animationStep2 addViewAnimation:viewAnimation21 forView:self.searchBar];
    
    if (self.alignment == HLSExpandingSearchBarAlignmentRight) {
        HLSViewAnimation *viewAnimation22 = [HLSViewAnimation animation];
        [viewAnimation22 transformFromRect:collapsedFrame
                                    toRect:CGRectMake(0.f,
                                                      roundf((CGRectGetHeight(self.frame) - kSearchBarStandardHeight) / 2.f),
                                                      kSearchBarStandardHeight,
                                                      kSearchBarStandardHeight)];
        [animationStep2 addViewAnimation:viewAnimation22 forView:self.searchButton];
    }
    
    HLSAnimation *animation = [HLSAnimation animationWithAnimationSteps:[NSArray arrayWithObjects:animationStep1, animationStep2, nil]];
    animation.tag = @"searchBar";
    animation.lockingUI = YES;
    animation.delegate = self;
    
    return animation;
}

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated
{
    // No animation if not displayed yet
    if (! _layoutDone) {
        _expanded = expanded;
        return;
    }
    
    if (_animating) {
        HLSLoggerWarn(@"The search bar is already being animated");
        return;
    }
    
    if (expanded) {
        if (_expanded) {
            HLSLoggerInfo(@"The search bar is already expanded");
            return;
        }
        
        _animating = YES;
        
        HLSAnimation *animation = [self expansionAnimation];
        [animation playAnimated:animated];        
    }
    else {
        if (! _expanded) {
            HLSLoggerInfo(@"The search bar is already collapsed");
            return;
        }
        
        _animating = YES;
        
        // The search bar does not store its text when it collapses
        self.searchBar.text = nil;
        
        // Remove all search bar additional controls
        self.searchBar.prompt = nil;
        self.searchBar.placeholder = nil;
        self.searchBar.showsBookmarkButton = NO;
        self.searchBar.showsSearchResultsButton = NO;
        
        [self.searchBar resignFirstResponder];
        
        HLSAnimation *reverseAnimation = [[self expansionAnimation] reverseAnimation];
        [reverseAnimation playAnimated:animated];
    }
}

#pragma mark Action callbacks

- (void)toggleSearchBar:(id)sender
{
    [self setExpanded:! _expanded animated:YES];
}

#pragma mark HLSAnimationDelegate protocol implementation

- (void)animationDidStop:(HLSAnimation *)animation animated:(BOOL)animated
{
    _animating = NO;
    
    if ([animation.tag isEqualToString:@"searchBar"]) {
        _expanded = YES;
        
        // Show search bar additional controls only when fully expanded (does not animate well, and we
        // do not want to animate UISearchBar subviews because we cannot control its view hierarchy)
        self.searchBar.prompt = self.prompt;
        self.searchBar.placeholder = self.placeholder;
        self.searchBar.showsBookmarkButton = self.showsBookmarkButton;
        self.searchBar.showsSearchResultsButton = self.showsSearchResultsButton;
        
        // At the end of the animation so that the blinking cursor does not move during the animation (ugly)
        [self.searchBar becomeFirstResponder];
        
        if ([self.delegate respondsToSelector:@selector(expandingSearchBarDidExpand:animated:)]) {
            [self.delegate expandingSearchBarDidExpand:self animated:animated];
        }
    }
    else if ([animation.tag isEqualToString:@"reverse_searchBar"]) {
        _expanded = NO;
        
        if ([self.delegate respondsToSelector:@selector(expandingSearchBarDidCollapse:animated:)]) {
            [self.delegate expandingSearchBarDidCollapse:self animated:animated];
        }
    }
    
    // Force layout so that the views resize properly, even if the expansion / collapsing animation occurs during
    // a device rotation
    [self layoutSubviews];
}

#pragma mark UISearchBarDelegate protocol implementation

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarShouldBeginEditing:)]) {
        return [self.delegate expandingSearchBarShouldBeginEditing:self];
    }
    else {
        return YES;
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarTextDidBeginEditing:)]) {
        [self.delegate expandingSearchBarTextDidBeginEditing:self];
    }
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarShouldEndEditing:)]) {
        return [self.delegate expandingSearchBarShouldEndEditing:self];
    }
    else {
        return YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarTextDidEndEditing:)]) {
        [self.delegate expandingSearchBarTextDidEndEditing:self];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBar:textDidChange:)]) {
        [self.delegate expandingSearchBar:self textDidChange:searchText];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBar:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate expandingSearchBar:self shouldChangeTextInRange:range replacementText:text];
    }
    else {
        return YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarSearchButtonClicked:)]) {
        [self.delegate expandingSearchBarSearchButtonClicked:self];
    }
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarBookmarkButtonClicked:)]) {
        [self.delegate expandingSearchBarBookmarkButtonClicked:self];
    }
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(expandingSearchBarResultsListButtonClicked:)]) {
        [self.delegate expandingSearchBarResultsListButtonClicked:self];
    }
}

@end
