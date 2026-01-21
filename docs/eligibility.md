# Eligibility System

In order to match members with programs and discounts, Suma has a robust eligibility system.

The eligibility system is relatively straightforward to describe:

- *Resources* have *eligibility requirements*.
- *Members* have *eligibility attributes*.
- If a member's eligibility attributes overlap a resource's eligibility requirements,
  the member can access the resource.

Now some vocabulary and nuance:
  - *Resources*: offerings, products within an offering, programs, vendor services (mobility) attached to a program, discounts (payment triggers).
  - *Eligibility attributes*: 60% AMI or below, 80% AMI or below, military veteran, member of a particular organization, role.
    - *Eligibility requirements* are the same as *eligibility attributes.*
      The term "requirements" is just meant to highlight the resource's relationship to the attribute. 
  - A member's *eligibility attributes* are always *additive.*
  - A resource's *eligibility requirements* can be expressed with *boolean AND/OR logic.*
    - That is, you can say "eligible to (military veterans) _OR_ (80% AMI _AND_ a member of Organization Z)".
  - *Eligibility attributes* are *accumulated* by a member through direct assignment, organization memberships,
    and roles (and organization roles).
    - That is, if Member A has Role B and is a member of Organization C, and Organization C has Role B and Role D,
      Member A will have the union of eligibility attributes for itself, Role B, Organization C, and Role D.
  - Attributes are *hierarchical.* If a resource has an eligibility requirement of 'X',
    then members who have an eligibility attribute of 'X', directly or as the parent of an attribute they do have,
    would be eligible.

## Implementation

There are two related implementation challenges: resolving eligibility, and maintaining eligibility descriptions.
They are related because resolving eligibility must either be very complex over a rich and diverse data structure
(and incur no additional eligibility attribute maintenance),
or simple over heavily denormalized data (ie, copying all attributes to be associated with the member).

To get around this, we use a materialized view that is rebuilt when eligibility tables change.