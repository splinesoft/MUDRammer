# encoding: UTF-8

class String
  def self.colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
  end

  def cyan
  self.class.colorize(self, 36)
  end

  def green
  self.class.colorize(self, 32)
  end
end

def is_circle
  ENV['CIRCLECI'] == 'true'
end

desc 'Install the bundle and perform other setup'
task :setup do
  
  xc_version = `xcodebuild -version`.chomp
  xc_path = `xcode-select -p`.chomp
  
  puts "Building with #{xc_version} in #{xc_path}...".cyan

  puts "Nuking output...".cyan
  sh "rm -rf output && mkdir -p output"
  
  Rake::Task['gems'].execute

  if is_circle
    puts "Setting up CocoaPods-Keys for CircleCI...".cyan

    keys = [ "HOCKEYBETA_KEY",
             "HOCKEYLIVE_KEY",
             "SPLINESOFT_AFFILIATE_KEY",
             "USERVOICE_FORUM_SITE",
             "USERVOICE_FORUM_ID" ]

    keys.each do |key|
      sh "bundle exec pod keys --project-directory=src set #{key} '-'"
    end
  end

  Rake::Task['pods'].execute
end

desc 'Install RubyGems'
task :gems do
  puts "Installing bundle...".cyan
  sh "bundle install --jobs=4 --retry=2 --path=vendor/bundle"
end

desc 'Install pods'
task :pods do
  pod_version = `bundle exec pod --version`.chomp
  puts "Installing Pods (CocoaPods #{pod_version})".cyan
  sh "bundle exec pod install --project-directory=src"
end

desc 'Build CI'
task :test do
  build_command = "set -o pipefail && xcodebuild "+
  "-workspace src/Mudrammer.xcworkspace "+
  "-scheme 'MUDRammer Dev' "+
  "-sdk iphonesimulator "+
  "-destination \"platform=iOS Simulator,name=iPhone 6\" "+
  "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES "+
  "clean test | bundle exec xcpretty -ct --report junit --output "
  
  if is_circle
    build_command += "$CIRCLE_TEST_REPORTS/junit.xml"
  else
    build_command += "output/junit.xml"
  end
  
  sh "#{build_command}"
end

desc 'Strips trailing whitespace in all project files. See https://github.com/jhersh/playgrounds'
task :ws do 
  ws = "xcrun swift ~/Dev/Playgrounds/SwiftSpace.playground/Contents.swift"
  sh "cd src/Mudrammer && #{ws}"
  sh "cd src/MRTests && #{ws}"
end

desc 'Lints MUDRammer with various static analyzers'
task :lint do

  puts "Linting MUDRammer...\n".cyan
  `mkdir -p output`

  sh "/usr/local/bin/cloc --exclude-dir=Pods --quiet --sum-one src"
  
  puts "\nFinding CocoaPods updates...".cyan
  sh "bundle exec pod outdated --project-directory=src"

  puts "\nFinding potentially unused imports...".cyan
  puts `bundle exec fui --path src/Mudrammer find`

  puts "\nLinting file header styles...".cyan
  puts `bundle exec obcd --path src/Mudrammer find HeaderStyle`
  puts `bundle exec obcd --path src/MRTests find HeaderStyle`

  puts "\nLinting with FauxPas...".cyan
  lint_log = ""
  
  if is_circle
    lint_log = "$CIRCLE_ARTIFACTS/fauxpas.txt"
  else
    lint_log = "output/fauxpas.txt"
  end
  
  sh "/usr/local/bin/fauxpas -t MUDRammer -b Debug -o human "+
     "--minErrorStatusSeverity None check src/Mudrammer.xcodeproj 2>/dev/null > #{lint_log}"
     
  puts "Wrote FauxPas lint results to #{lint_log}".cyan

end

desc 'Run lint and tests'
task :ci do
  Rake::Task["setup"].execute
  Rake::Task["test"].execute
  Rake::Task["lint"].execute
  sh "bundle exec slather"
end

desc 'Generate and print a single redemption code for a free copy of MUDRammer'
task :code do
  sh "bundle exec codes 1 "+
  "-u admin@splinesoft.net "+
  "-a com.splinesoft.theMUDRammer "+
  "-o code.txt --urls"
end

task :default => :test
