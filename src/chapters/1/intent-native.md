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
{{#include examples/unvendor.wa2:without_aws}}
```
 We use `core:source` to refer back to the
source of the `Store` - in a CloudFormation based workload, that will be
the `Resource`. Also note how we are now using `core:Evidence` to standardize where we
keep evidence facts.

So we `derive` the `evidence` from the CloudFormation level, and can build a `rule`
ontop of the evidence, not the CloudFormation implementation detail.

```wa2
{{#include examples/unvendor.wa2:stores_cfn}}
```
Note again that we place facts under `core:Evidence` to meet our rule expectations.
Instead of using an `if` statement to check the exist of the tag, we now use a `should` modal.
The `should` (like the `must`) will stop the derive execution, preventing evidence from being added,
but instead of a fatal error, it will be a warning.

> [!TIP]
> Using a `should` in a `derive` provides guidance to an engineer that
> is relevant at the implementation level. The `rule` will signal a fatal
> architectural error about the lack of classification, but the `derive` can tell the engineer
> what needs to be fixed at the CloudFormation level.

## Ensure all tests continue to pass

So now we can run again to ensure our refactoring has not broken anything:  
Let’s check the target again:
```bash
{{#include examples/unvendor.sh}}
{{#include examples/unvendor.txt}}
```

So we have fixed our first piece of debt, having policy to tied to implementation detail.
Now as WA2 adds new ways to ingest targets (API etc), and new vendors (Azure, GCP)
we won't have to change our polict, we will just add new derives to gather the evidence we need.

## Enforcing a taxonomy

Currently the tags against a Resource could contain any value.
So we want to make sure they follow our Data Classification Taxonomy.
Everyone has their own, so lets define ours and then make sure its being used.

So we can add a `enum` that lists all possible values, just like `core` did for `Node`.
```wa2
{{#include examples/taxonomy.wa2:DataCriticality}}
```

so we can write `should query`, with the `as()` function to convert the
`Value` of the `AWS Tag` into our enum `DataCriticality`
```wa2
{{#include examples/taxonomy.wa2:stores_cfn}}
```
Now we only derive evidence of Criticality if the tagging follows our taxonomy.
In theory this also allows different projects to use different taxonomy,
and our polict would still work.

> [!NOTE]
> the `[modal] [value] as([name])` syntax is truthy.  
> For our example if the value is not in
> the list of valid values in name, it evaluates to false.
> so since we used `should` a non-valid value stops us adding evidence

### Ensure all tests continue to pass

Let’s check the target again:
```bash
{{#include examples/taxonomy.sh}}
{{#include examples/taxonomy.txt}}
```

## Acting on Intent

So now we can step away from broad compliance tickboxes,
and instead use our intent to decide what must be done.
First we need another rule in our policy set:
```wa2
{{#include examples/protect.wa2:policy}}
```

### Critical stores should be resilient
We write the new rule that says that all critical stores must be resilient:
```wa2
{{#include examples/protect.wa2:rule}}
```

### Identify which stores are Critical
We are going to enrich our tagging logic to
identify if a store is critical or not based.
on our taxonomy:
```wa2
{{#include examples/protect.wa2:tagging}}
```

> [!TIP]
> we use the `match` keyword to return different
> values based on the `enum`.  
> Note how we flipped the logic, so that when
> we add a new value to the enum in the future,
> the rule we defensively protect us by assuming
> it is critical.

### Gather evidence from implementation

Finally we gather evidence of resilience, in this
example we just look for S3 buckets with replication
setup:
```wa2
{{#include examples/protect.wa2:evidence}}
```

We need to update our target to make this critical for our example:
```yaml
{{#include examples/protect.yaml}}
```

Let’s check the target again:
```bash
{{#include examples/protect.sh}}
{{#include examples/protect.txt}}
```

So the result is telling use that there are critical stores that
should be resilient but are not. That would be a very expensive
mistake to make in production.

We need to update our target to make this store resilient. Getting
this right is not simple (and in this example is not complete!).
So this would be ideal to put in your standard
goverance (more later on this) set of `derives`:
```yaml
{{#include examples/resilient.yaml}}
```
Let’s check the target again:
```bash
{{#include examples/resilient.sh}}
{{#include examples/resilient.txt}}
```