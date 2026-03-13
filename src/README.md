

# Introduction
Products and their context change constantly.  
Architectures must evolve with them.

Yet ensuring systems follow best practices remains largely manual.

Best practices live in long PDFs, written without your context.
Compliance becomes a checkbox exercise, replacing informed decisions with overly broad rules.
Reviews happen late, risking expensive mistakes and incidents.
All systems are now distributed, but best practice knowledge is not.
Teams run hybrid, multi-vendor systems - but our tools reason about them one property at a time.

Well-Architected 2 (WA2) is an _architecture reasoning system_, not a compliance scanner.

WA2 builds a graph of your system and evaluates it against your intent.

As you build or evolve architectures, WA2 guides you, explaining best practices, what they imply, and how their consequences ripple through your architecture.

Instead of asking:
* Have you backed up this S3 bucket?
WA2 determines:
* Are your _critical stores_ protected from data loss?

## What WA2 is
WA2 consists of:
* **Book**: this guide, explaining both the thinking and the tool.
* **Intents language**: a small language for expressing architectural policies.
* **Framework**: vendor-independent best practices built on architectural concepts.
* **Tooling**: 
  * **CLI**: enforcement in CI/CD.
  * **Extension**: editor integration that guides you around problems as you build.

## The Big Idea

WA2 separates:
* _How a system is implemented_

from
* _What it must guarantee_

**Rules** add **evidence** to a shared **graph**.  
**Policies** evaluate that **evidence**.

Vendor-specific logic produces **facts**.  
Architectural intent consumes them.

This keeps governance _clean and portable_.  
And allows us to establish an _evidence chain_ - back to source code.

## Why This Matters
Architectures have grown _far_ more complex.  
Our tooling has not kept up.

WA2 changes how we think about architecture:
* Architecture becomes queryable.
* Best practices become executable.
* Governance becomes scalable.
* Vendor specifics become interchangeable.
* Developers get guidance in context.

# Current Scope

* Today WA2 supports AWS CloudFormation (JSON & YAML).
* It is designed to support additional systems over time.