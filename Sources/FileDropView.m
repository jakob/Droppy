#import "FileDropView.h"


@implementation FileDropView

-(void)drawRect:(NSRect)dirtyRect {
    NSRect borderRect = NSInsetRect([self bounds], 2, 2);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:12 yRadius:12];
    [borderPath setLineWidth:4];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.15] setStroke];
    CGFloat lineDash[] = {14,10};
    [borderPath setLineDash:lineDash count:2 phase:0];
    [borderPath stroke];
}

@end
