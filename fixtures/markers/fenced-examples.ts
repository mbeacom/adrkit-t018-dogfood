// Negative fixture: markers inside fenced blocks are examples, not declarations.
//
// A fenced block is where a file *shows* the marker syntax. adrkit treats a run
// of three or more backticks or tildes leading a line as a fence, and skips
// everything until a closing run of at least the same length of the same
// character. Documentation of the marker feature would otherwise claim to live
// under every decision it illustrates.
//
// Expected declaration set for this file: exactly `0002`, from the single
// unfenced marker at the very bottom. Asserted as `NEG-2` / `POS-7`.

/*
Everything between the fences below is an example.

```
// @adr 0001
```

A tilde fence does not close a backtick fence, and vice versa:

~~~
// @adr 0003
```
// @adr 0004
~~~

A longer fence closes a shorter one, but never the reverse:

````
// @adr 0006
```
// @adr 0007
````

An info string keeps the fence open across the language tag:

```ts
// @adr 0008
```
*/

export const fencedExamplesAbove = true;

// @adr 0002
// The one real declaration in this file, deliberately placed after every fenced
// example so that an unclosed-fence regression would swallow it and be caught,
// rather than leaving the assertion trivially satisfied by a marker at the top.
export const declared = true;
