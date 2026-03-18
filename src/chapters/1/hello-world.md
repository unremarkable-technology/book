# Hello, World!

With the WA2 `intent` binary installed, we can check our first system!
As is traditional in learning a new language, we open with the `Hello, world!` example,
of course we actually want something closer to:  
```Success: target satisfies intent```

but "_Hello, Success: target satisfies intent_" is not as catchy as "Hello, World!"

## A target
We need a ``target`` system to check.
Our target will be this simple AWS CloudFormation template.
It creates a single S3 bucket.

```yaml
{{#include examples/naive.yaml}}
```

We might _assume_ that this bucket stores data because it is named `DataBucket`,
but that is just a guess at this point.

## Write a test
We want to ask a question of the target, did you classify your data?

Let's write a test to do that:
```wa2
{{#include examples/naive.wa2}}
```
The code above is written in the `intent` language:
* we `use` some supporting _namespaces_ for AWS CloudFormation and data classification
* we create a `profile` to group policies.
* we define a `policy` describing what `must` be *satisfied*.
* finally the `rule` that is evaluated

When WA2 is asked to look at the `target`,
it automatically converts the CloudFormation into the *WA2 graph*.
So our rule can `query(aws:cfn:Resource)` to find all
CloudFormation resources in the graph.

Our rule also uses `query(resource/data:Criticality)` to
check if the resource has data Criticality evidence.
The `must` keyword is a modal verb (RFC 2119[^modals]) that
tells WA2 how this rule is satisfied. In this case
we used `must` so what follows must be *truthy* (not empty, false, or 0).


## Run the test
We can now use the CLI to check whether our `target` satisfies our `intent`:
```bash
{{#include examples/naive.sh}}
{{#include examples/naive.txt}}
```

We were looking for _evidence_ of classification.
Right now, no such evidence exists.  
We have not _yet_ told WA2 how that evidence should be produced.
**So the policy fails, correctly.**

> [!NOTE]
> There are three sections in the output
> * PREPARE: to analyse by loading and parsing files
> * RESULTS: show success or issues
> * VALIDATION: of target
> Validation is done in parallel, and uses the CloudFormation Specification from AWS.
> Since validation against the specification takes time, we optimise the dev experience
> by running it in the background, hence why it appears last.
>
> Add the `--novalidation` parameter to disable validation for even faster execution.

You can view this as a Test-Driven Development (TDD[^tdd]) approach:
1. write a test
1. see the test fail
1. write the simplest code that helps it pass
1. refactor as needed

We've done the first two steps already, so let's write that simple code to help it pass.

## Help it pass
Our rule looks for evidence of data classification.
We need to say how data classification is expressed in our CloudFormation implementation.
In CloudFormation, we normally do this with "[AWS Tags](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-resource-tags.html)".
In our CloudFormation we plan to use a `DataCriticality` tag, so lets query for that.

We want this code to run every time WA2 tries to satisfy our intent.
We use the `derive` keyword to say it is going to add to the graph:
```wa2
{{#include examples/tagged.wa2:focus}}
```

Our intent code queries for all CloudFormation resources.
If a `resource` has an AWS Tag, and it has a `DataCriticality` key - 
then we add `data:Criticality` evidence to that `resource` in the graph.

### Fix the target
Update the target CloudFormation to include the classification tag:
```yaml
{{#include examples/tagged.yaml}}
```

### Run the test (again)
Let’s check the target again:
```bash
{{#include examples/tagged.sh}}
{{#include examples/tagged.txt}}
```

The policy is satisfied because the required architectural fact now exists.

### What just happened?
When WA2 evaluates a system, it builds a graph representation of the architecture and reasons about it.

Your CloudFormation becomes nodes and relationships in the **WA2 graph**.

Rules and derives operate on that graph.

```
       CloudFormation
              ↓
           WA2 Graph
           ↓       ↑
        derive → evidence
                   ↓
                 rule
                   ↓
                policy
                   ↓
                profile
                   ↓
           evaluation result
```
* `derive` statements add `evidence` to the `graph`
* `rules` evaluate that evidence
* `policies` group `rules` into architectural requirements

Vendor-specific logic derives facts about the system.  
Architectural policies evaluate those facts without depending on implementation details.

### Peering at the graph
Sometimes its useful to look at the graph, which is displayed
as a containment tree with `→` to indicate non-containing edges:
```bash
{{#include examples/graph.sh}}
{{#include examples/graph.txt}}
```

## Refactor as needed

Our tests are green, but they carry technical debt:
* Our policy is tightly coupled to CloudFormation
* The evidence is weak; we are not validating the tag value
* It asks a compliance question: "did you do it?", not "did you need to?"

Let's address that in the next chapter.

[^tdd]: https://en.wikipedia.org/wiki/Test-driven_development

[^modals]: RFC 2119 https://www.ietf.org/rfc/rfc2119.txt