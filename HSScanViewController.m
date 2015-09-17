//
//  HSScanViewController.m
//  
//
//  Created by Philip Bernstein on 9/15/15.
//
//

#import "HSScanViewController.h"

@interface HSScanViewController ()

@end

@implementation HSScanViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    highlightView = [[UIView alloc] initWithFrame:CGRectZero];
    highlightView.backgroundColor = [UIColor clearColor];
    highlightView.layer.borderColor = [UIColor redColor].CGColor;
    highlightView.layer.borderWidth = 1.0f;
    [self.view addSubview:highlightView];
    
    session = [AVCaptureSession new];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    [device setVideoZoomFactor:3.5];
    [device unlockForConfiguration];
    
    NSError *error = nil;
    
    input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (input) {
        [session addInput:input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:output];
    
    output.metadataObjectTypes = [output availableMetadataObjectTypes];
    
    prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    prevLayer.frame = self.view.bounds;
    
    [self.view.layer addSublayer:prevLayer];
    [session startRunning];

}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    for (AVMetadataObject *metadata in metadataObjects)
    {
        if ([metadata.type isEqualToString:AVMetadataObjectTypePDF417Code])
        {
            barCodeObject = (AVMetadataMachineReadableCodeObject *)[prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
            detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            highlightViewRect = barCodeObject.bounds;
            break;
        }
        else
        {
            //What do you get for this line if it doesn't decode?
            NSLog(@"%@",metadata.type);
        }
    }
    if (!detectionString)
        return;
    
    NSMutableArray *arrFixedData=[[NSMutableArray alloc]initWithObjects:@"DCS",@"DCT",@"DCU",@"DAG",@"DAI",@"DAJ",@"DAK",@"DCG",@"DAQ",@"DCA",@"DCB",@"DCD",@"DCF",@"DCH",@"DBA",@"DBB",@"DBC",@"DBD",@"DAU",@"DCE",@"DAY",@"ZWA",@"ZWB",@"ZWC",@"ZWD",@"ZWE",@"ZWF", @"DAA", nil];
    NSMutableArray *arrDriverData=[[NSMutableArray alloc]initWithObjects:@"Customer Family Name",@"Customer Given Name",@"Name Suffix",@"Street Address 1",@"City",@"Jurisdction Code",@"Postal Code",@"Country Identification",@"Customer Id Number",@"Class",@"Restrictions",@"Endorsements",@"Document Discriminator",@"Vehicle Code",@"Expiration Date",@"Date Of Birth",@"Sex",@"Issue Date",@"Height",@"Weight",@"Eye Color",@"Control Number",@"Endorsements",@"Transaction Types",@"Under 18 Until",@"Under 21 Until",@"Revision Date", @"Customer Family Name", nil];
    
    
    NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
    for (int i=0; i<[arrFixedData count]; i++)
    {
        NSRange range = [detectionString rangeOfString: [arrFixedData objectAtIndex:i] options: NSCaseInsensitiveSearch];
        if (range.location != NSNotFound)
        {
            NSString *temp=[detectionString substringFromIndex:range.location+range.length];
            
            NSRange end = [temp rangeOfString:@"\n"];
            if (end.location != NSNotFound)
            {
                temp = [temp substringToIndex:end.location];
                temp =[temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                temp=[temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
            }
            [dict setObject: (temp) ? temp : @"" forKey:[arrDriverData objectAtIndex:i]];
        }
    }
    
    [self.view bringSubviewToFront:highlightView];
    highlightView.frame = highlightViewRect;
    
    [self processData:dict];

}

-(void)processData:(NSDictionary *)dict {
    NSString *state = [dict objectForKey:@"Jurisdction Code"];
    NSString *expiration = [dict objectForKey:@"Expiration Date"];
    NSString *postal = [dict objectForKey:@"Postal Code"];
    NSString *address = [dict objectForKey:@"Street Address 1"];
    NSString *dob = [dict objectForKey:@"Date Of Birth"];
    NSString *sex = [dict objectForKey:@"Sex"];
    NSString *eye = [dict objectForKey:@"Eye Color"];
    NSString *idNumber = [dict objectForKey:@"Customer Id Number"];
    NSString *city = [dict objectForKey:@"City"];
    NSString *lastName = [dict objectForKey:@"Customer Family Name"];
    NSString *firstName = [dict objectForKey:@"Customer Given Name"];
    
    NSLog(@"STATE: %@", state);
    NSLog(@"EXPIRATION: %@", expiration);
    NSLog(@"POSTAL: %@", postal);
    NSLog(@"ADDRESS: %@", address);
    NSLog(@"DOB: %@", dob);
    NSLog(@"SEX: %@", sex);
    NSLog(@"EYE: %@", eye);
    NSLog(@"ID #: %@", idNumber);
    NSLog(@"CITY: %@", city);
    NSLog(@"NAME: %@ %@", firstName, lastName);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [session stopRunning];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [session startRunning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
