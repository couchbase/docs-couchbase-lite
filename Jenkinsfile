pipeline {
    agent none
    options {
        timeout(time: 10, unit: 'MINUTES') 
    }
    stages {
        stage("Validate Build") {
            agent { label 's61113u16 (litecore)' }
            steps {
                sh 'jenkins/dotnet_build.sh'
            }
        }
    }
}