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
                        sh 'jenkins/dotnet_build.sh'
                    }
                }
                stage("Validate C") {
                    agent { label 's61113u16 (litecore)' }
                    steps {
                        sh 'jenkins/c_build.sh 3.2.0'
                    }
                }
                stage("Validate iOS") {
                    agent { label 'mobile-builder-ios-pull-request' }
                    steps {
                        sh 'jenkins/ios.sh 3.2.0 1.0.0'
                    }
                }
            }
        }
    }
}