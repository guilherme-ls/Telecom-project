function [val] = physconst(name)
  if name == "Boltzmann"
    val = physical_constant("Boltzmann constant");
  end;
end;
