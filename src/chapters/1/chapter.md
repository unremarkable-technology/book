# Chapter 1
Let’s start with the classic “Hello, world” example.
To do that we need a few things:
* WA2 installed - so we can run the example
* A stack template, written in CloudFormation YAML to evaluate
* A policy, written in WA2 the _Intent_ language, to say what we want to evaluate for
* A rule that generates architectural evidence from our CloudFormation implementation.

by the end of this chapter you will understand
* WA2 does not check raw properties.
* It checks architectural facts.
* Architectural facts can be derived from vendor-specific implementations.

## 1 Installation
(todo)

## 2 A minimal stack
This is a very simple AWS stack. It creates an S3 bucket.
```yaml
{{#include examples/stack_1.yaml}}
```

## 3 A minimal policy
Our minimal policy says that every CloudFormation resource must be classified.
It does not define how classification is implemented — only that it must exist.
```wa2
{{#include examples/intent_1.wa2}}
```

## 4 Run WA2
```bash
{{#include examples/bash_1.sh}}
{{#include examples/bash_1.txt}}
```

WA2 is not checking for a specific tag.
It is checking whether architectural evidence of classification exists.
Right now, no such evidence has been generated.

The policy requires a fact. We have not yet told WA2 how that fact is produced. The policy fails — correctly.

## 5 Generating evidence
Now we define how classification is expressed in our CloudFormation implementation.
In this example, we express classification using a _DataCriticality_ tag,
so we add this code to myintent.wa2:

```wa2
{{#include examples/intent_2.wa2:focus}}
```

## 6 Fix the stack
Update the stack to include the classification tag:
```yaml
{{#include examples/stack_2.yaml}}
```

Let’s check the stack again:
```bash
{{#include examples/bash_2.sh}}
{{#include examples/bash_2.txt}}

```

The policy is satisfied because the required architectural fact now exists.