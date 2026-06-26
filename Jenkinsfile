pipeline {
    agent none
    options {
        timeout(time: 10, unit: 'MINUTES')
    }
    stages {
        stage("Validate Build") {
            parallel {
                stage("Validate C#") {
                    agent { label 's61113u16 (litecore)' }
                    steps {
                        sh 'jenkins/dotnet_build.sh 3.4.0 2.0.0'
                    }
                }
                stage("Validate C / C++") {
                    agent { label 's61113u16 (litecore)' }
                    steps {
                        sh 'jenkins/c_build.sh 3.4.0'
                        sh 'jenkins/cpp_build.sh 3.4.0'
                    }
                }
                stage("Validate iOS") {
                    agent { label 'mobile-builder-ios-pull-request' }
                    steps {
                        sh 'jenkins/ios.sh 3.4.0 2.0.0'
                    }
                }
                stage("Validate Android") {
                    agent { label 'cbl-android' }
                    steps {
                        sh 'jenkins/android_build.sh 3.4.0 2.0.0'
                    }
                }
            }
        }
    }
}
