# Pantry

The pantry is the user's declared stock of ingredients, each with a quantity and a unit. Every scaled recipe draws against it.

## Entry

The cook adds an ingredient by name, quantity and unit. Quantities convert to the recipe's unit system on read.

## Depletion

Marking a recipe as cooked subtracts its quantities from the pantry. A quantity never goes below zero.
