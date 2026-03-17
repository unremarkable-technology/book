# Intent driven

In this chapter we show how to refactor to remove our test's technical debt:
1. Our policy is very tied to CloudFormation
3. It's not robust evidence, we are not checking the contents of the tag
2. It's a compliance checkbox "did you do it?", no "did you need to?"

Our first task is to remove the direct linkage to CloudFormation in our policy.

## A higher vista
Let's take a higher vista, and look at architecture at a higher level.

The WA2 Framework provides the `core` namespace which provides these key elements:
```wa2
{{#include examples/core.wa2:structs}}
```

The foundations of the `core` namespace (and indeed WA2) are these:
* We reason about `Nodes`, which has three possible variations: 
  * `Store` data
  * `Run` code
  * `Move` information
* We arrange a set of `Node` in our graph into a `Workload`
* We use `Evidence` to enrich the graph

## Projecting into our vista

As we saw in the previous chapter, the intent language allows us to write
queries at an AWS CloudFormation level:  
```query(aws:cfn:Resource)```  

This is critical to be able to create evidence at a Vendor level,
but we want to _reason_ about **architecture**, not **implementation**.

The WA2 Framework provides the `aws:cfn` namespace which projects from
CloudFormation into the `core:Node` type. So for example in this snippet
we can see how it maps `aws:type` into `Node:Store`
```wa2
{{#include examples/cfn.wa2:project}}
```

This means that if you add
```wa2
use core
use aws:cfn
```
to your wa2 intent file, you automatically get these projections.
This allows us to rewrite our policy rule without reference to AWS.

## Policy independent of vendor

Now that we can work at a higher level, we can write policy that is
vendor neutral. In the last chapter we were checking all CloudFormation Resources for
data classification, which makes no sense for a AWS IP Address (for example).
Now we can start with quering only stores:
```wa2
{{#include examples/intent_3.wa2:without_aws}}
```
 We use `core:source` to refer back to the
source of the `Store` - in a CloudFormation based workload, that will be
the `Resource`. Also note how we are now using `core:Evidence` to standardize where we
keep evidence facts.

So it's only the derivation of evidence that works at CloudFormation level.

```wa2
{{#include examples/intent_3.wa2:stores_cfn}}
```
Note again that we place facts under `core:Evidence` to match our rule expectations.
Instead of using an `if` statement to check the exist of the tag, we now use a `should` modal.
The `should` (like the `must`) will stop the derive, preventing evidence from being added,
but instead of a fatal error, it will be a warning.

> [!TIP]
> Using a `should` in a `derive` provides guidance to an engineer that
> is relevant at the implementation level. The `rule` will signal a fatal
> error about the lack of classification, but the `derive` can tell the engineer
> what needs to be fixed at the CloudFormation level.

## Ensure all tests continue to pass

So now we can run again to ensure our refactoring has not broken anything:  
Let’s check the target again:
```bash
{{#include examples/bash_3.sh}}
{{#include examples/output_3.txt}}
```

So we have fixed our first piece of debt, having policy to tied to implementation detail.
Now as WA2 adds new ways to ingest targets (API etc), and new vendors (Azure, GCP)
we won't have to change our polict, we will just add new derives to gather the evidence we need.

## Enforcing a taxonomy

Currently the AWS Tags against a Resource could contain anything.
So we want to make sure they follow our Data Classification Taxonomy.
Everyone has their own, so lets define ours and then make sure its being used.

So we can add a `enum` that lists all possible values, just like `core` did for `Node`.
```wa2
{{#include examples/intent_4.wa2:DataCriticality}}
```

so we can write `should query`, with the `as()` function to convert the
`Value` of the `AWS Tag` into our enum `DataCriticality`
```wa2
{{#include examples/intent_4.wa2:stores_cfn}}
```
Now we only derive evidence of Criticality if the tagging follows our taxonomy.
In theory this also allows different projects to use different taxonomy,
and our polict would still work.

### Ensure all tests continue to pass

Let’s check the target again:
```bash
{{#include examples/bash_4.sh}}
{{#include examples/output_4.txt}}
```


## Using policies informed by Intent
[todo: backup data if its critical using evidence not]
