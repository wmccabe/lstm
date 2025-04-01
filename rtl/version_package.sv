package version_package;
    localparam logic [7:0] ID    = 34;
    localparam logic [7:0] MAJOR = 1;
    localparam logic [7:0] MINOR = 1;
    localparam logic [7:0] PATCH = 3;
    localparam logic [31 : 0] VERSION_REGISTER = {ID, MAJOR, MINOR, PATCH};
endpackage
    
