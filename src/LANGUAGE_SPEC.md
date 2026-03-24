# WA2 Intent Language Specification

**Version**: 0.1.18  
**Status**: Draft

---

## 1. Overview

The WA2 Intent Language is a declarative domain-specific language for expressing architectural policies, validation rules, and derived knowledge over a graph-based model of infrastructure.

### 1.1 Purpose

WA2 enables:

- **Classification**: Deriving semantic meaning from infrastructure configuration
- **Validation**: Asserting architectural requirements
- **Guidance**: Providing actionable feedback with appropriate severity

### 1.2 Execution Phases

The language operates in two ordered phases:

1. **Derive Phase** — Enrich the graph with computed facts (model building)
2. **Rule Phase** — Evaluate conditions and emit findings (validation only)

Policies and profiles control which rules are active and how their outcomes affect overall policy success.

### 1.3 Design Principles

- Queries are the primary way to inspect the model
- Modal operators (`must`/`should`/`may`) control both severity and control flow
- Derives cannot fail; rules can
- Policies select and constrain rules; they don't modify rule behavior

---

## 2. Lexical Structure

### 2.1 Character Set

Source files are UTF-8 encoded.

### 2.2 Whitespace and Comments

```ebnf
{{#include ./grammar.ebnf:whitespace_and_comments}}
```

Comments and whitespace are ignored except as token separators.

### 2.3 Keywords

```
namespace  use        type       struct     enum       predicate
instance   rule       derive     policy     profile
must       should     may
let        for        in         if         else       match      as
query      add        true       false      empty
```

### 2.4 Identifiers

```ebnf
{{#include ./grammar.ebnf:identifiers}}
```

**Examples**: `foo`, `core:Store`, `aws:cfn:Resource`

### 2.5 Literals

```ebnf
{{#include ./grammar.ebnf:literals}}
```

### 2.6 Operators and Punctuation

```
{  }  (  )  [  ]  /  *  =  ,  :  =>  _
```

---

## 3. Grammar

### 3.1 Top-Level Items

```ebnf
{{#include ./grammar.ebnf:toplevel}}
```

### 3.2 Declarations

```ebnf
{{#include ./grammar.ebnf:declarations}}
```

### 3.3 Rules and Derives

```ebnf
{{#include ./grammar.ebnf:rules_derives}}
```

### 3.4 Policies and Profiles

```ebnf
{{#include ./grammar.ebnf:policies_profiles}}
```

### 3.5 Statements

```ebnf
{{#include ./grammar.ebnf:statements}}
```

### 3.6 Expressions

```ebnf
{{#include ./grammar.ebnf:expressions}}
```

### 3.7 Annotations

```ebnf
{{#include ./grammar.ebnf:annotations}}
```
---

## 4. Type System

### 4.1 Graph Model

The system operates on a directed graph of **entities** connected by **predicates**.

| Concept | Description |
|---------|-------------|
| Entity | A node in the graph with a unique identity |
| Predicate | A named relationship between entities or from entity to literal |
| Triple | (Subject, Predicate, Object) where Object is Entity or Literal |

### 4.2 Built-in Types

| Type | Description |
|------|-------------|
| `wa2:Type` | A type definition |
| `wa2:Predicate` | A predicate definition |
| `wa2:Namespace` | A namespace |
| `wa2:subTypeOf` | Enum variant relationship |
| `wa2:type` | Type assignment predicate |
| `wa2:contains` | Containment relationship |

### 4.3 Enum Types

Enums define a closed set of valid values:

```wa2
enum DataCriticality {
    Disposable,
    NonCritical,
    Important,
    BusinessCritical,
    MissionCritical
}
```

Each variant becomes an entity with `wa2:subTypeOf` pointing to the enum type.

### 4.4 Evaluation Results

Expressions evaluate to one of:

| Result | Description |
|--------|-------------|
| `Entity` | Single entity reference |
| `Set` | Zero or more entities |
| `Literal` | String value |
| `Empty` | Absence of value |

---

## 5. Semantics

### 5.1 Truthiness

A value is **truthy** if:

| Result | Truthy When |
|--------|-------------|
| `Entity` | Always |
| `Set` | Non-empty |
| `Literal` | Non-empty string and not `"false"` |
| `Empty` | Never |

A value is **falsy** if not truthy.

### 5.2 Query Semantics

```wa2
query(path/to/target)
```

- Traverses the graph following the path
- Returns a `Set` of matching entities or literals
- Empty set if no matches

**Variable Binding**: If the first path segment is an unqualified name that matches a bound variable, traversal starts from that entity:

```wa2
let source = query(store/core:source)
let tags = query(source/aws:Tags)  // starts from 'source'
```

**Predicates**: Filter results:

```wa2
query(core:Store[core:Evidence/data:isCritical])  // stores with critical evidence
query(source/aws:Tags/*[aws:Key = "Environment"])  // tags with specific key
```

### 5.3 Modal Statements

Modal statements are the primary mechanism for expressing requirements.

```wa2
must <expr> { subject: <expr>, area: <name>, message: <string> }
should <expr> { ... }
may <expr> { ... }
```

**Evaluation**:

1. Evaluate expression
2. If truthy → continue to next statement
3. If falsy:
   - Create finding with specified metadata
   - Apply guard behavior based on modal

**Modal Behavior Matrix**:

| Modal | On Falsy | Guard | Severity |
|-------|----------|-------|----------|
| `must` | Fail | Yes | Error |
| `should` | Warn | Yes | Warning |
| `may` | Pass | No | Info |

**Guard Behavior**: When guard applies, remaining statements in the current block are skipped. Outer scopes continue.

```wa2
for store in stores {
    should query(store/core:Evidence) {
        message: "Store needs evidence"
    }
    // If above fails, this line is skipped for this store:
    let evidence = query(store/core:Evidence)
    add(evidence, wa2:contains, fact)
}
// Loop continues with next store
```

### 5.4 As-Conversion

The `as(Type)` operator validates and converts values:

```wa2
let criticality = query(tag/aws:Value) as(DataCriticality)
```

**Behavior**:

1. Evaluate inner expression to get literal value
2. Check if value matches a variant of the target enum
3. If valid → return the value
4. If invalid → return `Empty`

**Type Not Found**: If the target type does not exist, this is always an error regardless of context (framework bug).

### 5.5 Match Expressions

```wa2
match <expr> {
    Pattern1, Pattern2 => result1,
    Pattern3 => result2,
    else => default
}
```

- Evaluates expression to get a literal value
- Tests patterns in order
- Returns result of first matching arm
- `else` matches anything

### 5.6 Add Expressions

```wa2
add(subject, predicate, object)
```

- Creates a triple in the graph
- Returns the subject entity
- `_` as subject creates a blank node

```wa2
let evidence = add(_, wa2:type, core:Evidence)  // new blank node
add(store, wa2:contains, evidence)               // link to store
```

### 5.7 Empty Check

```wa2
empty(expr)
```

- Returns truthy (`"true"`) if expression is empty/falsy
- Returns `Empty` if expression is non-empty/truthy

---

## 6. Execution Model

### 6.1 Phase Order
```
1. Load Model (e.g., CloudFormation projection)
2. Load Framework (types, predicates, derives, rules, policies)
3. Select Profile
4. Derive Phase (fixed-point, model building)
5. Rule Phase (sequential by policy order, validation only)
6. Collect Findings
```

### 6.2 Derive Phase

**Purpose**: Enrich the graph with computed facts.

**Constraints**:

| Allowed | Not Allowed |
|---------|-------------|
| `add` statements/expressions | `must` modal |
| `should`, `may` modals | — |
| Blank nodes (`_`) | — |

**Execution**:

- Runs to fixed-point (until no new facts are added)
- Order of derives does not matter (monotonic)
- Guards operate normally (`should`/`may` skip remaining statements in block on failure)
- Findings from `should` are collected as warnings

**Rationale**: Derives build the model; they cannot cause overall failure. A missing tag might prevent evidence creation, but that's detected by rules.

### 6.3 Rule Phase

**Purpose**: Evaluate conditions and produce findings. Rules do not modify the model.

**Constraints**:

| Allowed | Not Allowed |
|---------|-------------|
| `must`, `should`, `may` modals | `add` statements/expressions |
| Queries | Blank nodes (`_`) |

**Execution**:

- Model is stable (derives have completed)
- Only rules referenced by the selected profile's policies are executed
- Rules execute in policy declaration order
- Modal statements evaluate immediately

**Rationale**: Rules validate a complete model. Since derives run first, all computed facts are available when rules execute.

### 6.4 Policy and Profile

**Profile**: Selects which policies are active.
```wa2
profile production {
    policy data_protection
    policy compliance_checks
}
```

**Policy**: Binds rules with execution modals that control sequential flow.
```wa2
policy data_protection {
    must all_stores_classified
    must critical_stores_protected
    should encryption_enabled
}
```

**Two-Phase Execution**:

1. **Derive phase** completes first (model building)
2. **Rule phase** executes rules in policy order

**Policy Modal Semantics**:

The policy modal controls whether execution continues to the next rule based on whether the current rule produced any Error-level findings:

| Policy Modal | Rule Outcome | Effect |
|--------------|--------------|--------|
| `must` | Has Errors | Stop policy, report Fail |
| `must` | No Errors | Continue to next rule |
| `should` | Has Errors | Note degraded, continue |
| `should` | No Errors | Continue to next rule |
| `may` | Any | Always continue |

A rule "passes" if it produces no Error-level findings (warnings and info are acceptable).

**Policy Outcomes**:

| Outcome | Meaning |
|---------|---------|
| `Pass` | All rules passed |
| `Degraded` | All `must` rules passed, but some `should` rules failed |
| `Fail` | At least one `must` rule failed |

**Example**:
```wa2
policy protect_stores_based_on_classification {
    must all_stores_must_be_classified    // stops if this produces Errors
    must ensure_critical_stores_protected // only runs if above passed
}
```

**Per-Entity Dependencies**: Handled naturally through evidence model. A rule checking for protection evidence will only match stores that have classification evidence, because the derive that creates protection evidence depends on classification evidence existing.

### 6.5 Fixed-Point Iteration

Derives execute in a fixed-point loop:
```
repeat until no change:
    for each derive:
        execute body
        track (derive, binding) to avoid reprocessing same entity
```

Maximum iterations are bounded to prevent infinite loops.

Rules do not use fixed-point iteration; they execute once per entity in policy order.

### 6.6 Namespace Resolution

- Unqualified names inside `namespace X { ... }` resolve to `X:name`
- `use` statements import namespaces for reference
- Type references in `as(Type)` are qualified by current namespace if unqualified

---

## 7. Findings

### 7.1 Structure

A finding consists of:

| Field | Type | Description |
|-------|------|-------------|
| `subject` | Entity | The entity this finding relates to |
| `area` | Entity | The type/category for educational content |
| `message` | String | Human-readable action to resolve |
| `severity` | Enum | `core:Error`, `core:Warning`, `core:Info` |
| `assertion` | String | Rule name and modal that produced this |

### 7.2 Production

Findings are produced only by:

- Modal statements (`must`, `should`, `may`)

`as(Type)` produces no findings; it returns `Empty` on invalid values.

### 7.3 Severity Mapping

| Modal | Severity Entity |
|-------|-----------------|
| `must` | `core:Error` |
| `should` | `core:Warning` |
| `may` | `core:Info` |

---

## 8. Examples

### 8.1 Complete Example

```wa2
use core
use aws:cfn
use data

// Define classification taxonomy
enum DataCriticality {
    Disposable,
    NonCritical,
    Important,
    BusinessCritical,
    MissionCritical
}

// Activate policies
profile production {
    policy protect_critical_data
}

// Define policy requirements
policy protect_critical_data {
    must all_stores_classified
    must critical_stores_protected
}

// Rule: all stores need classification
rule all_stores_classified {
    for store in query(core:Store) {
        let source = query(store/core:source)
        must query(store/core:Evidence/data:Criticality) {
            subject: source,
            area: data:Criticality,
            message: "Store must have criticality classification"
        }
    }
}

// Rule: critical stores need protection
rule critical_stores_protected {
    for store in query(core:Store[core:Evidence/data:isCritical]) {
        let source = query(store/core:source)
        must query(store/core:Evidence/data:isResilient) {
            subject: source,
            area: data:isResilient,
            message: "Critical stores must be protected from loss"
        }
    }
}

// Derive: extract classification from tags
derive classification_from_tags {
    for store in query(core:Store[core:source/aws:cfn:Resource]) {
        let source = query(store/core:source)
        let dc_tag = query(source/aws:Tags/*[aws:Key = "DataCriticality"])
        
        should dc_tag {
            subject: source,
            area: DataCriticality,
            message: "Add a DataCriticality tag to this resource"
        }
        
        let criticality = query(dc_tag/aws:Value) as(DataCriticality)
        should criticality {
            subject: source,
            area: DataCriticality,
            message: "DataCriticality tag must be a valid classification"
        }
        
        // Create evidence
        let evidence = add(_, wa2:type, core:Evidence)
        add(store, wa2:contains, evidence)
        let fact = add(_, wa2:type, data:Criticality)
        add(evidence, wa2:contains, fact)
        
        // Determine if critical
        let is_critical = match criticality {
            Disposable, NonCritical, Important => false,
            else => true
        }
        
        // Mark as critical if applicable
        if is_critical {
            let crit_fact = add(_, wa2:type, data:isCritical)
            add(evidence, wa2:contains, crit_fact)
        }
    }
}
```

### 8.2 Guard Behavior Example

```wa2
derive example {
    for item in query(core:Item) {
        // If this fails, remaining statements for this item are skipped
        should query(item/core:required_field) {
            message: "Item needs required_field"
        }
        
        // Only reached if above passes
        let value = query(item/core:required_field)
        add(item, core:processed, value)
    }
    // Loop continues with next item regardless of guard
}
```

### 8.3 As-Conversion Examples

**Standalone validation** (returns value or Empty):

```wa2
let criticality = query(tag/aws:Value) as(DataCriticality)
should criticality {
    message: "Tag value must be valid"
}
```

---

## 9. Reserved for Future

The following features are not yet implemented but are under consideration:

- Aggregation functions (`count`, `sum`, `all`, `any`)
- Arithmetic expressions
- Rule return values and policy constraints on outcomes
- Negation in queries (`not`)
- Optional chaining in queries
- Import/export between files
- Macros and code generation

---

# 10. References
## 10.1 Grammar Summary

```ebnf
{{#include ./grammar.ebnf:all}}
```

---

## 10.2 Severity Reference

| Context | Modal | Finding Produced | Severity | Guard |
|---------|-------|------------------|----------|-------|
| Modal statement | `must` | Yes | Error | Yes |
| Modal statement | `should` | Yes | Warning | Yes |
| Modal statement | `may` | Yes | Info | No |
| `expr as(T)` | invalid | No | — | Return Empty |
| `expr as(T)` | type not found | Always Error | — | — |

---

## 10.3 Built-in Predicates

| Predicate | Domain | Range | Description |
|-----------|--------|-------|-------------|
| `wa2:type` | Entity | Type | Assigns type to entity |
| `wa2:subTypeOf` | Type | Type | Enum variant relationship |
| `wa2:contains` | Entity | Entity | Containment/child relationship |
| `core:source` | Node | Resource | Links derived node to source |
| `core:subject` | Finding | Entity | Entity the finding relates to |
| `core:area` | Finding | Type | Category for educational content |
| `core:message` | Finding | Literal | Human-readable guidance |
| `core:severity` | Finding | Severity | Error/Warning/Info |
| `core:assertion` | Finding | Literal | Rule and modal that produced finding |

## 10.4 Item Type Constraints

| Item | Queries | Add | Allowed Modals | Creates |
|------|---------|-----|----------------|---------|
| `derive` | ✓ | ✓ | `should`, `may` | Warning, Info |
| `rule` | ✓ | ✗ | `must`, `should`, `may` | Error, Warning, Info |

These constraints are enforced at compile time (lowering phase).