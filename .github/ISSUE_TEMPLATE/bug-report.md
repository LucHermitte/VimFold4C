---
name: Bug report
about: Create a report to help us fix, or improve folding

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Paste a code which is incorrectly folded.

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.
In that case I'll also be interested in a screenshot after a:

```vim
:call lh#c#fold#verbose(2)
zX
zR
```

And in the result of 

```vim
:echo map(range(1,line('$')), 'lh#c#fold#expr(v:val)')
```

**Additional context**
Add any other context about the problem here. In particular your settings may be of help:

- what are the value of `g:fold_options` and of `b:fold_options`
- what does `:set` display -- you can copy it into your clipboard with `:let @+ = join(lh#askvim#execute('set'), "\n")`
