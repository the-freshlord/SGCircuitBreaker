Pod::Spec.new do |s|
    s.name                  = "SGCircuitBreaker"
    s.version               = "1.1.4"
    s.summary               = "A Swift implementation of the Circuit Breaker design pattern"
    s.homepage              = "https://github.com/eman6576/SGCircuitBreaker"
    s.license               = { :type => "MIT" }
    s.author                = { "Manny Guerrero" => "emanuelguerrerodev@gmail.com" }
  
    s.ios.deployment_target = "9.0"
    s.osx.deployment_target = "10.9"
    s.source                = { :git => "https://github.com/eman6576/SGCircuitBreaker.git", :tag => s.version }
    s.source_files          = "Sources/SGCircuitBreaker/*.swift", 
    s.exclude_files         = "Classes/Exclude"
  end