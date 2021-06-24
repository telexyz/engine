Think Julia https://benlauwens.github.io/ThinkJulia.jl/latest/book.html
Learn Julia https://github.com/crstnbr/JuliaNRW21

# Julia

Julia is the first modern language to make a reasonable effort to solve the two-language problem. It is a high-level, dynamic language with powerful features that make for very productive programming. At the same time, code written in Julia usually runs very quickly, almost as quickly as code written in statically typed languages.

Finally, Julia will work for you at both ends of the compute spectrum. On one hand, its performance and expressiveness allows it to run embedded use cases on low-powered processors and it is fully supported on ARM processors, and works well on the Raspberry Pi, which makes it a perfect environment for teaching programming. 

At the other end of the spectrum, Julia has been used to run large-scale machine learning applications on some of the world's largest super-computers. The Celeste project used Julia Build and Atlas of the Sky, where the computation ran at an amazing 1.5 petaflops (1 petaflop is 10^15 floating point operations per second, or a thousand million million), using 1.3 million threads. This was the first time any dynamic language had broken the petaflop barrier. So, Julia can run on machines large and small, scaling massively in both directions.

When the creators of Julia launched the language into the world, they said the following in a blog post entitled Why We Created Julia, which was published in early 2012:

"We want a language that's open source, with a liberal license. We want the speed of C with the dynamism of Ruby. We want a language that's homoiconic, with true macros like Lisp, but with obvious, familiar mathematical notation like Matlab. We want something as usable for general programming as Python, as easy for statistics as R, as natural for string processing as Perl, as powerful for linear algebra as Matlab, as good at gluing programs together as the shell. Something that is dirt simple to learn, yet keeps the most serious hackers happy. We want it interactive and we want it compiled. (Did we mention it should be as fast as C?)"

High-performance, indeed nearly C-level performance, has therefore been one of the founding principles of the language. It's built from the ground up to enable the fast execution of code.

Julia is a Just In Time (JIT) compiled language, rather than an interpreted one. This allows Julia to be dynamic, without having the overhead of interpretation. This compilation infrastructure is built on top of LLVM. (Think of JavaScript JIT v8 Engine but also AOT compile to Machine Code)

 Julia's syntax and semantics have been carefully designed to allow high-performance execution, and a large part of this is due to how Julia uses types in the language. We will, of course, have much more to say about types in Julia throughout this book. At this stage, suffice it to say that Julia's concept of types is a key ingredient of its performance.

 Julia allows us to introspect the native code that runs on the CPU. Using this facility, we can see that very different code is generated for integer and floating point arguments. So, let's look at the following machine code, generated for squaring an integer:
 
 ```jl
   julia> @code_native 3^2
     pushl %eax
     decl %eax
     movl $202927424, %eax ## imm = 0xC186D40
     addl %eax, (%eax)
     addb %al, (%eax)
     calll *%eax
     popl %ecx
     retl
```
Let's now look at the following code, generated for squaring a floating point value:
 ```jl
   julia> @code_native 3.5^2
     vcvtsi2sdl %edi, %xmm1, %xmm1
     decl %eax
     movl $1993314664, %eax ## imm = 0x76CF9168
     .byte 0xff .byte 0x7f .byte 0x00
     addb %bh, %bh
     loopne 0x68
     nopw %cs:(%eax, %eax)
 ```

 You will notice that the code looks very different (although the actual meaning of the code is not relevant for now). You will notice that there are no runtime type checks in the code. This gets to the heart of Julia's design and its performance claims.

 The ability of the compiler to reason about types is due to the combination of a sophisticated dataflow-based algorithm, and careful language design that allows this information to be inferred from most programs before execution begins. Put in another way, the language is designed to make it easy to statically analyze its data types.

 If there is a single reason for Julia being such a high-performance language, this is it. This is why Julia is able to run at C-like speeds while still being a dynamic language. _TYPE INFERENCE_ AND *CODE SPECIALIZATION* ARE AS CLOSE TO A SECRET SAUCE AS JULIA GETS. 

 It is notable that, outside this type inference mechanism, the Julia compiler is quite simple. It does not include many of the advanced Just in Time optimizations that Java and JavaScript compilers are known to use. When the compiler has enough information about the types within the code, it can generate optimized, straight-line code without many of these advanced techniques.

 More at https://julialang.org/assets/research/julia-fresh-approach-BEKS.pdf

 Type inference means that the compiler is usually able to figure out the types of variables when necessary. Hence, you can usually write high-level code without fighting with the compiler about types, and still achieve superior performance.
