# Dialyzer & Type Specifications

> Lisp Flavoured Erlang function and data type specifications and
> definitions for Dialyzer.

Within this document we will provide the necessary tools to start
reinforcing your LFE code with type specifications and
definitions. These will (soon!) be readable by the Dialyzer tool for
even more amazing distributed Lisp code!

This document borrows heavily from the
[Learn You Some Erlang](https://learnyousomeerlang.com) chapter on
[Type Specifications and Erlang](https://learnyousomeerlang.com/dialyzer). It
is of course focused on how to utilise the type system in LFE. This
system is built on top of the functionality that Dialyzer provides,
any information that may be lacking here will more than likely appear
on the Learn You Some Erlang site. If you think it should be included
here, lodge an issue!

If you're running a sufficiently recent version of Erlang, then the
`dialyzer` module should already be available to you. However in order
for it to be of any use, you must prepare the PLT (Persistent Lookup
Table). This table stores information about modules and
applications. We won't spend too long on setting up Dialyzer as there
are already some great guides
[here](http://learnyousomeerlang.com/dialyzer) and
[here](http://gertm.blogspot.com.au/2012/06/getting-started-with-dialyzer-for.html)
and of course the
[`man` page](http://www.erlang.org/doc/man/dialyzer.html).

Building the PLT the first time:
```
$ dialyzer --build_plt --apps erts kernel stdlib crypto mnesia sasl
```

Throughout this guide we will begin with demonstrating what the
'un-typed' version of the code will look like. Then we enhance with
types to demonstrate their use in various situations.

> Should I briefly cover some Dialyzer details like type inference and
> discrepencies and how the sucess typing system works here? Or just
> completely defer to the LYSE/dialyzer page? I feel like I should
> cover it at least briefly so we know what to avoid in our LFE types
> as well. Because they'll look different...

### Types of Types

The type system for LFE supports the Erlang _union_ and _built-in_
types. With _singleton_ types as well, these simply refer to the value
itself. For example:
```
'|some atom|	| Any atom can be its own singleton type
42				| A given integer
#() or (list)	| An empty list
#{} or (tuple)	| An empty tuple
#B or (binary)	| An empty binary
```

Below is a table of the built-in Erlang types, and their LFE
counterparts. Note that somethings become reserved words inside of a
type definition because of the availability of specific types, such as
process ids, ports, or references.

| Erlang Term | LFE Term | Description |
|-------------|----------|-------------|
| `any()` | `'any` | Any Erlang term |
| `none()` | `'nil` or `'none` | Special Dialyzer term for when no term should match. According to LYSE it is "synonymous with _this stuff won't work_.". |
| `pid()` | `'pid` | A process identifier |
| `port()` | `'port` | A port is the representation of a file description, socket, et al. In the shell they appear as #Port<0.638> |
| `reference()` | `'ref` | Unique values returned by (make_ref) or erlang:monitor/2 |
| `atom()` | `'atom` | General atom type |
| `binary()` | `#B` | General binary type |
| `<<_:N>>` | `#B(size N)` | Binary of known size where `N` is the size |
| `<<_:_*N>>` | `#B(_ (size N) *)` | Binary of `N` size but unspecified length |
| `<<_:N,_:_*K>>` | `#B(_ (size N) _ (size K) *)` | Combination of the above specifiers |
| `integer()` | `'int` or `'integer` | Any integer |
| `N..M` | `(.. N M)` | A range of integers. From `N` to `M`, Dialyzer reserves the right to expand this range into a larger when. |
| `non_neg_integer()` | `'non_neg_int` or `'non_neg_integer` | Integer that is greater or equal to 0 |
| `pos_integer()` | `'pos_int` or `'pos_integer` | Integer greater than 0 |
| `neg_integer()` | `'neg_int` or `'neg_integer` | Integers up to and including `-1` |
| `float()` | `'float` | Any floating point number. |
| `fun()` | `(fun)` | Any kind of function. |
| `fun((...) -> Type)` | `(fun (..) Type)` | An anonymous function of any arity that returns `Type`. `(fun (..) 'int)`, for example. |
| `fun(() -> Type)` | `(fun () Type)` | An anonymous function of 0 arity that returns `Type`. |
| `fun((Type1,Type2) -> Type)` | `(fun (Type1 Type2) Type)` | An anonymous function of a specific arity that only accepts the types specified in the given order, and returns `Type`. `(fun ('int 'float) #('int))`, for example. |
| `[]` | `#()` or `(list)`| An empty list. |
| `[Type]` | `#(Type)` or `(list Type)` | A list containing a given type. This is a polymorphic type that expects a inner type, `#('int)`, for example. |
| `[Type, ...]` | `#(Type ...)` | A special list type that means the list cannot be empty. |
| `tuple()` | `#{}` or `(tuple)` | Any tuple. |
| `{Type1, Type2}` | `#{Type1 Type2}` or `(tuple Type1 Type2)` | A tuple of known size with known types. |

There is also a way to indicate that a _specific_ atom is part of a definition or specification. The syntax plays merry hell with the Markdown table syntax provided by Github so I'll just lay it out here:
```lfe
'|specific atom|
```
You simply wrap the atom in pipes `|` after the quote symbol. So a binary tree node _type_ could be defined as:
```erlang
#{'|node| 'any 'any 'any}
```
... corresponding to:
```erlang
#{node LeftTree Value RightTree}
```

Phew, geez that's a lot of types. But you might be able to see how you
can effectively structure the types of your various LFE definitions
and specifications. But sometimes things might be too specific, or too
vague for your needs. This is where the construction of _union_ types
comes into play.

Union types in Erlang, using the `|` operator, allow us to create our
own types that are combinations of different types. So `TypeName` is
represented by `Type1 | Type2 | ... | TypeN`. To use examples directly
from LYSE:

>As such, the number() type, which includes integers and floating
>point values, could be represented as integer() | float(). A boolean
>value could be defined as 'true' | 'false'. It is also possible to
>define types where only one other type is used. Although it looks
>like a union type, it is in fact an alias.

Because Erlang and Dialyzer are so nice to us, there is a stack of
these _union_ types already defined for us! But we're not using
Erlang, so lets have a look at how they are using in LFE.

| Erlang Term | LFE Term | Description |
|-------------|----------|-------------|
| `term()` | `'term` | Equivalent to `any()` and because other tools use `term()` in their code. Alternatively you can use the `_` as an alias of `'term` or `'any`. |
| `boolean()` | `'bool` or `'boolean` | Equivalent to the `true` or `false` atoms. |
| `byte()` | `'byte` | Defined as `0..255`, it's any valid byte in existence. |
| `char()` | `'char` | Defined as `0..16#10ffff`, but it's not clear whether this type refers to specific standards for characters or not. Reallllly general so as to avoid conflicts. |
| `number()` | `'num` or `'number` | `integer()` or `float()` |
| `maybe_improper_list()` | `#(improper)` or `#(maybe_improper)` | This is an alias for `maybe_improper_list(any(), any())` for improper lists in general. |
| `maybe_improper_list(Type)` | `#(improper Type)` or `#(maybe_improper Type)` | Where `Type` is any given type. Is an alias for `maybe_improper_list(Type, any())`. |
| `string()` | `'string` or `'str` | Defined as `[char()]`, a list of characters. |
| `nonempty_string()` | `'nonempty_string` or `'nonempty_str` | As above, except the list cannot be empty. Defined as `[char(), ...]`. |
| `iolist()` | `'iolist` | Funnily enough, this is the `iolist` type! |
| `module()` | `'module` | Alias of atom, but used for specifying the required type as a module name. |
| `timeout()` | `'timeout` | Union of `'non_neg_int` and `'infinity`. |
| `node()` | `'node` | An Erlang node name, which is an atom. |
| `no_return()` | `'no_return` | Alias of `'nil`, intended to be used in the return type of functions. It is primarily designed for annotating functions that loop (hopefully) forever, thus never returning. |

Defining your own _union_ type in LFE is as easy as using the pipe operator `|` at the head of a list to create the _union_ type from the elements of that list. Like so:
```lisp
;; This syntax is still to be decided upon as the pipe operator plays
;; all sorts of hell with different parsers and Emacs modes and
;; annoying things that probably won't make a lick of difference to
;; how simple it may be to implement. But making everything else work
;; with the notation might not be worth the trouble... BUT YOU NEVER KNOW.
(| 'int 'float)
```

That's a lot of types! But how do we actually __USE__ them?! Recall
our quick and nasty binary tree definition from earlier `#{'|node|
'any 'any 'any}`. Now that we have some more information and saucy
types, lets declare an actual type definition in our module!

The syntax for a module level type definition in Erlang is:
```erlang
-type TypeName() :: TypeDefinition.
```
So to define our tree type we simply layout our types into the required structure:
```erlang
-type tree() :: {'node', tree(), any(), tree()}.
```
Note the support for recursive types!!

Before we go too much further though, lets see how we do this in LFE:
```lisp
(type-of typename (typedefinition))
```
Therefore:
```lisp
(type-of tree '(#{'|node| tree 'any tree}))
```
When it's a simple definition such as this you may omit including the
definition in a list, which simplifies it to:
```lisp
(type-of tree #{'|node| tree 'any tree})
```

But just looking at the type definition there isn't way to determine
which of the `tree` types in the tuple refer to the _left_ or _right_
subtrees. There is a special syntax for type definitions that let us
provide named comments for the types. Greatly increasing the knowledge
that can be gained by simply looking at the type definitions.

Like so, in Erlang:
```erlang
-type tree() :: {'node', Left::tree(), Value::any(), Right::tree()}.
```
And thus for LFE:
```lisp
;; This lets you annotate the types that matter
(type-of tree #{'|node| (:: Left tree) (:: Value 'any) (:: Right tree)})
;; This feels like it's verging on a lot of ceremony, but to me it looks really clear.
```
or
```lisp
;; This could just be shorthand for the above, would be consistent if
;; we support (: erlang foo) and (erlang:foo) for function calls. ??
(type-of tree #{'|node| Left::tree Value::any Right::tree})
```

That definition alone won't work, because it doesn't allow for our
`tree` to be empty. How do we deal with this without making our types unreadable?

We can see from the above definition that Dialyzer and LFE support
recursive type definitions! (_insert happy dance here_) We're about to
see the next piece of magic that Dialyzer has in store for us, those
of us joining from the world of Haskell should immediately recognise
the following:
```erlang
-type tree() :: {'node', 'nil'}
	          | {'node', Left::tree(), Value::any(), Right::tree()}.
```

Wait..Is that?! Oh no..

Yes, that's right everyone!! Dialyzer and LFE support algebraic data
types!! Happy days !

How does with work in LFE? Simply provide another definition to the
list for that data type:
```lisp
(type-of tree '(#{'|node| '|nil|}
                #{'|node| (:: Left tree) (:: Value any) (:: Right tree)}))
```
Now we have a `tree` data type that is either an empty tree or a node
with potentially two children. Gee that was easy...For our Haskell
friends that would be the same as:
```haskell
data Tree = Empty
          | Node Tree a Tree
```
If we wanted to we could even specify a `Maybe` type of our very own:
```lisp
(type-of maybe ('nil
                #{'|just| 'any}))
```
Okay I'll stop now.

Dialyzer also supports adding types to your records, these can be
either any of the _built-in_ or _union_ types or ones that you've
defined yourself.

The normal Erlang syntax is:
```erlang
-record(user, {name="" :: string(),
     	       notes :: tree(),
	           age  :: non_neg_integer(),
	           friends=[] :: [#user{}]}
			   bio :: string() | binary()).
```
This record is quite straight forward and represents a user that has a
name stored as a `string()`, we keep some notes in a `tree()` format
because why not. Their `age` must be a `non_neg_integer()` and we even
keep a list of `#user{}` records in a `list()` on this type. Their
`bio` is kept as either a normal `string()` or in a `binary()` format
for convenience.

You will note that the `#user{}` notation is used to represent the
record type in the `list`. This is because you can use `#recordname{}`
to indicate something is a `record` of type `recordname`. Some prefer
to keep the type definitions to a uniform style so they will declare
an alias for the record type like so:
```erlang
-type Type() :: #Record{}.
```
We can do this in LFE as well if you feel so inclined:
```lisp
;; Any thoughts on an easier way to do this?
(type-of user (record user))
```
or maybe...
```lisp
(type-of user #R/user)
```

Now that we have an alias for our user record and we know what types
we're using lets see how we do this in LFE:
```lisp
(defrecord user (name "" (:: 'string))
                (notes (:: tree))
                (age (:: 'non_neg_int))
                (friends '() (:: #(user)))
                (bio (:: (| 'string #B))))
```

### Function Types

You're also able to provide type information for your functions as well.
```lisp
(deftypedfun foo (('int 'int) 'float)
	((a b)
		(div a b)))
```
This function takes two integers and returns a floating point
value. The type signature contains the arguments to the function
inside a list as the first element and the return value as the second
argument.
```lisp
((function arg types) return type)
```
The default Dialyzer technique for handling a function that has
different types for different branches of the function is to use union
types:
```erlang
-spec foo(integer(), integer()) -> float() | {atom(), string()}.
```
So we can use the same mechanism in LFE types like so:
```lisp
(deftypedfun foo (('int 'int) (| 'float '(tuple 'atom 'string)))
	((a b) (when (and (> b 0 ) (> a 0)))
		(div a b))
	((_ _)
		(tuple 'error '"Arguments not greater than zero")))
```
The union type denotes that this function has different return types.

In the future it would be fun to be able to use the following
technique for functions that have multiple return types:
```lisp
(deftypedfun foo (('int 'int) -> a)
	((a b) (-> 'float) (when (and (> a 0) (> b 0)))
		(div a b))
	((_ _) (-> (tuple 'atom 'string))
		(tuple 'error '"Arguments not greater than zero.")))
```
My thinking is that the _->_ lists would be combined in a union
function in the primary type signature. So you could also do something
like this:
```lisp
(deftypedfun foo
	((a b) (('int 'int) 'float) (when (and (> a 0) (> b 0)))
		(div a b))
	((a) ('int (('int) 'float))
		(lambda (b) (div a b))))
```
### Exporting Types
#### Examples
