pipeline{
    agent any 
    stages{
        stage('checkout'){
            steps{
                echo 'Checking out..'
            //  checkout code from git repository
            
        }
        }
        stage('build'){
            steps{
                echo 'Building..'
                //compile code here a java code
                sh 'javac ToUpper.java'
            }
        }
        stage('test'){
            steps{
                echo 'Testing..'
                //run test cases here
                sh 'java ToUpper test'
            }
        }
        stage('deploy'){
            steps{
                echo 'Deploying..'
            }
        }
    }
}