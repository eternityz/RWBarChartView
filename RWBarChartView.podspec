Pod::Spec.new do |s|

  s.name         = "RWBarChartView"
  s.version      = "1.0.0"
  s.summary      = "Scrollable chart view for bar graphs. "

  s.description  = <<-DESC
                   A scrollable, highly customizable and easy to use charting view for bar graphs.
                   DESC

  s.homepage     = "https://github.com/eternityz/RWBarChartView"

  s.license      = 'MIT'

  s.author             = { "eternityz" => "id@zhangbin.cc" }
  s.social_media_url = "http://twitter.com/eternity1st"

  s.platform     = :ios, '7.0'

  s.ios.deployment_target = '7.0'

  s.source       = { :git => "https://github.com/eternityz/RWBarChartView.git", :tag => "1.0.0" }

  s.source_files  = 'RWBarChartView', 'RWBarChartView/**/*.{h,m}'

  s.requires_arc = true

end
