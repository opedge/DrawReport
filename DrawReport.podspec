Pod::Spec.new do |s|
    s.name     = 'DrawReport'
    s.platform = :ios
    s.version  = '0.1'
    s.license  = 'MIT'
    s.summary  = 'Library for reporting UI bugs.'
    s.homepage = 'https://github.com/opedge/DrawReport'
    s.authors  = { 'Oleg Poyaganov' => 'opedge@gmail.com' }
    s.source   = { :git => 'https://github.com/opedge/DrawReport.git', :tag => "0.1" }
    s.requires_arc = true
    s.ios.deployment_target = '6.0'
    s.public_header_files = 'DrawReport/{DRPReporter,DRPReporterViewController}.h'
    s.source_files = 'DrawReport/*.{h,m}'
end
