Just a quickly thrown together lump of code that can be used to perform
various transformations on patches producible and consumable by Git.

There hasn't been any attempt to make this clean or bug-free. This is
mostly a proof of concept that allows me to test some ideas and get
a tool that I can use asap.

I'm not sure this belongs on CPAN, so it's not there yet. If you want
to install it, you can follow this procedure:

```
perl Build.PL
./Build --prefix=~/.local install
```

This will install all the necessary files into your home directory.

It's possible that your Perl installation will not look for modules
in your home directory. In that case, export the PERL5LIB variable:

```
export PERL5LIB=~/.local/lib64/perl5/5.38/
```

The actual directory might differ in your case, use the one printed
by the installation command.
