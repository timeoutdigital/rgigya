require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RGigya do
  
  it "should use the socialize url when making a socialize api call" do
    RGigya.stub(:required_parameters) {
      ''
    }
    # we pass in the "_" replaced with "." already
    url = RGigya.build_url("socialize.getUserInfo",{})
    url.should match(/https:\/\/socialize-api.gigya.com/)
  end
  
  
  
  it "should use the gm url when making a game mechanic api call" do
    RGigya.stub(:required_parameters) {
      ''
    }
    # we pass in the "_" replaced with "." already
    url = RGigya.build_url("gm.notifyAction",{})
    url.should match(/https:\/\/gm.gigya.com/)
  end
  
  
  it "should use the comments url when making a comment api call" do
    RGigya.stub(:required_parameters) {
      ''
    }
    # we pass in the "_" replaced with "." already
    url = RGigya.build_url("comments.getTopStreams",{})
    url.should match(/https:\/\/comments.gigya.com/)
  end
  
  it "should raise a bad param error if UID is nil" do
    expect {
      RGigya.build_url('socialize.getUserInfo', {:uid => nil})
    }.to raise_error(RGigya::UIDParamIsNil)
  end
  
  it "should raise a bad param error if siteUID is nil" do
    expect {
      RGigya.build_url('socialize.getUserInfo', {:siteUID => nil})
    }.to raise_error(RGigya::SiteUIDParamIsNil)
  end
  
  it "should fill in the required parameters on request" do
    # we pass in the "_" replaced with "." already
    params = RGigya.required_parameters
    params.should match(/apiKey=#{CGI.escape(GIGYA_API_KEY)}/)
    params.should match(/secret=#{CGI.escape(GIGYA_API_SECRET)}/)
    params.should match(/format=json/)    
  end
  
  it "should succeed with a result code of 0 from gigya" do 
    params = RGigya.check_for_errors({'errorCode' => 0})
    params.should have_key('errorCode')
  end
  
  
  it "should return nil and not raise an error with a limit reached error" do 
    results = RGigya.check_for_errors({'errorCode' => 400124})
    results.should be_nil
  end
  
  it "should raise an error when we pass in a bad parameter" do
    expect {
      RGigya.check_for_errors({
        'errorCode' => 400002
      })
    }.to raise_error(RGigya::BadParamsOrMethodName)
  end
  
  it "should raise an error when an errorcode other than 0,400002, or 400124 is returned" do
    # Buffering the log
    buffer = StringIO.new
    $stdout = buffer
    expect {
      RGigya.check_for_errors({
        'errorCode' => 4034934
      })
    }.to raise_error(RGigya::ErrorCodeReturned)
    $stdout = STDOUT
  end
  
  it "should report method missing if method does not start with socialize" do
    expect {
      RGigya.method_missing(:abc,{})
    }.to raise_error(NameError)
    expect {
      RGigya.method_missing(:socialize_getUserInfo)
    }.to raise_error(RGigya::BadParamsOrMethodName)
  end
  
  
  it "should report method missing if method does not start with gm" do
    expect {
      RGigya.method_missing(:abc,{})
    }.to raise_error(NameError)
    expect {
      RGigya.method_missing(:gm_notifyAction)
    }.to raise_error(RGigya::BadParamsOrMethodName)
  end
  
  
  it "should report method missing if method does not start with comments" do
    expect {
      RGigya.method_missing(:abc,{})
    }.to raise_error(NameError)
    expect {
      RGigya.method_missing(:comments_getComments)
    }.to raise_error(RGigya::BadParamsOrMethodName)
  end
  
  it "should not respond to method starting without socialize,gm, or comments" do
    RGigya.respond_to?(:abc,false).should be_false
  end
  
  it "should respond to method starting with socialize" do
    RGigya.respond_to?(:socialize_getUserInfo,false).should be_true
  end
  
  
  it "should respond to method starting with gm" do
    RGigya.respond_to?(:gm_notifyAction,false).should be_true
  end
  
  it "should respond_to method starting with comments" do
    RGigya.respond_to?(:comments_getComments,false).should be_true
  end
  
  it "should print log to standard out" do
    str = "This should print to the screen"
    buffer = StringIO.new
    $stdout = buffer
    RGigya.log(str)
    $stdout = STDOUT
    buffer.rewind
    buffer.read.should == str + "\n"
  end
  
  
  it "should print log to standard out" do
    # buffer the input and check
    str = "This should print to the screen"
    buffer = StringIO.new
    $stdout = buffer
    RGigya.log(str)
    $stdout = STDOUT
    buffer.rewind
    buffer.read.should == str + "\n"
  end
  
  
  it "should log to the Rails log if rails exists" do
    # Mock and Stub Rails.logger.info
    Rails = mock("Rails")
    Rails.stub(:logger) {  
      logger = mock("Logger");
      logger.stub(:info) do |str|
        puts "mocked_data=#{str}"
      end
      logger
    }
    
    # buffer the input and check
    str = "This should print to the screen"
    buffer = StringIO.new
    $stdout = buffer
    RGigya.log(str)
    $stdout = STDOUT
    buffer.rewind
    buffer.read.should == "mocked_data=" + str + "\n"
    # Remove the rails object so it doesn't interfere with tests below
    Object.send(:remove_const, :Rails)
  end
    
  it "should return a result of false if we pass a bad method" do
    HTTParty.stub(:get) do |url,options|
      nil
    end
    RGigya.parse_results("socialize_notAMethod",{}).should be_false
  end
    
  it "should raise json error if gigya returns bad json" do
    HTTParty.stub(:get) do |url,options|
      Response = mock("Response")
      Response.stub(:body) {
        '{'
      }
      Response
    end
    
    expect {
      RGigya.parse_results("socialize_notAMethod",{}).should be_false
    }.to raise_error(RGigya::JSONParseError)
  end
    
     
  it "should raise a response error if the gigya call fails" do
    HTTParty.stub(:get) do |url,options|
      raise SocketError
    end
    
    expect {
      RGigya.parse_results("socialize_notAMethod",{}).should be_false
    }.to raise_error(RGigya::ResponseError)    
  end
  
  it "should raise a response error if the gigya call times out" do
    HTTParty.stub(:get) do |url,options|
      raise Timeout::Error
    end
    
    expect {
      RGigya.parse_results("socialize_notAMethod",{}).should be_false
    }.to raise_error(RGigya::ResponseError)
    
  end
  
  
  # Actual tests that modify the gigya account below
  
  it "should login a user" do
    
    userInfo = {
      'nickname' => 'Gigems', 
      'email' => 'ralph@cloudspace.com',
      'firstName' => 'Ralph', 
      'lastName' => 'Masterson'
    }
    
    response = RGigya.socialize_notifyLogin({
      :siteUID => '1',
      :userInfo => userInfo.to_json
    })
  end
  
  it "should register a user" do
    uid = get_uid
    RGigya.socialize_notifyRegistration({
      :UID => uid,
      :siteUID => '1',
    })
    
  end
  
  it "should get the users info" do
    uid = get_uid
    response = RGigya.socialize_getUserInfo({
      :UID => uid,
    })
    response['nickname'].should match 'Gigems'
  end
  
  
end