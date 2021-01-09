
build:
	cfhighlander cfcompile s3-databucket

test:
	cfn-lint out/yaml/s3-databucket.compiled.yaml

deploy: build
	aws cloudformation deploy --template out/yaml/s3-databucket.compiled.yaml --stack-name s3-databucket