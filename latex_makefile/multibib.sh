#!/bin/csh

foreach aux (`find . -depth 1 -name "*.aux"`)
	set name = `basename $aux .aux`
	bibtex $name
end
