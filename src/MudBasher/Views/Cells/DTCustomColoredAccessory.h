// http://www.cocoanetics.com/2010/10/custom-colored-disclosure-indicators/

@interface DTCustomColoredAccessory : UIControl
{
	UIColor *_accessoryColor;
	UIColor *_highlightedColor;
}

@property (nonatomic, copy) UIColor *accessoryColor;
@property (nonatomic, copy) UIColor *highlightedColor;

+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color;

@end
