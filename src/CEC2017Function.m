function value = CEC2017Function(x,functionID)
%CEC2017Function  Thin CEC2017 wrapper (row vector in, scalar out).
%   Fresh wrapper of the audited cec17_func MEX (same semantics as the
%   historical harness): the MEX expects a column vector and opens
%   "input_data/..." relative to the CURRENT WORKING DIRECTORY, therefore any
%   caller must run from data/cec2017 (see experiments/runner_cec.m).
value=cec17_func(x',functionID);
value=value(1);
end
