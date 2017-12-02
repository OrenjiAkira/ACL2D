
# Adventure Collision Library 2D

A simple collision library for 2D top-down games.

It allows tiles of uniform dimensions that can be either
rectangles (AABB) or axis-aligned rectangular triangles.
Bodies can be either rectangles or circles.

Please note that this is for simple top-down adventure games.
Too many _moving bodies_ can result in performance issues.
I didn't use any complex algorithms to make it more efficient
because simply there is no need. Also because I wanted to allow
bodies of different dimensions to work, so I couldn't separate them
in tile-based grids.

The one thing I like about this code is that tile-collision is rather
efficient, yet it's powerful enough that it allows diagonal tiles with
smooth edges.

## Dependencies

This module needs [CPML][cpml-repo] and consequently it uses LUAjit to
work more efficiently. It is also made for [LÖVE2D](https://love2d.org),
but it works on its own too.

Add this repository to a folder called 'ACL2D' inside your project's directory,
and you're set.

## Usage

[ under construction ]

## Credits

Kudos for [CPML][cpml-repo] for its vectorial modules. I used very similar
code to the 'intersect' module as well, but based solely on 2D geometry.
Go check the project out.

[cpml-repo]: https://github.com/excessive/cpml

