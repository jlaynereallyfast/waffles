# stdlib.groupadd

## Description

Manages groups

## Parameters

* state: The state of the resource. Required. Default: present.
* group: The group. Required. namevar.
* gid: The gid of the group. Optional.

## Example

```shell
stdlib.groupadd --group jdoe --gid 999
```

