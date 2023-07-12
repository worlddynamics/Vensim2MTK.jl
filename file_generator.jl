# important information: for now, it is necessary to separate the parameters from the equations with at least one table, that may be empty.

using XML

filepath = "C:\\Users\\maelc\\OneDrive\\Documents\\stage\\New_parser_vensim_julia\\exemples\\Dice.xmile"
 # change this to the filepath to the model to translate


function setup(filepath)
    filename=filepath
    doc=read(filename,Node)
    root=doc[end]
    len = size(children(root[3][1]),1)
    return filename,doc,root,len
end

#The xml file of an exported vensim model is like this: 
#header with version information and the like;
#simulation details, eg the start of the simulation 
#and then the model, formated like this: 
#    Stocks, representing variables of the model 
#    First Aux objects: equations 
#    Second Aux objects: tables 
#    Third Aux objects: parameters. 

# the idea here is to find the indexes of where in the tree those sections are. 
# when the first Aux object is find we have the index for the first section; then we'll have to check one layer deeper, 
# for when it's not "eqn" objects a ymore but "gf" for tables 
# then find where the tables end by recognizing the return of "eqn" object. 
#the model start at a certain depth: root[3][1]



function is_a_table(node)
    tag(node[3])=="gf" 
end
function ind(node)
    counter = 0
    stocks_ind = 0
    eqn_ind = 0
    tables_ind = 0
    cdrns=children(node)
    for child in cdrns 
        if child.tag == "aux" && (stocks_ind + eqn_ind + tables_ind) == 0
            stocks_ind = counter 
            counter = counter + 1
        elseif stocks_ind>0 && eqn_ind==0 && is_a_table(child) 
            eqn_ind = counter
            counter = counter+1
        elseif eqn_ind>0 && !is_a_table(child)
            tables_ind=counter
            return (stocks_ind,eqn_ind,tables_ind)
        else 
            counter = counter + 1
        end
    end
end

#now, let's gather the parameters in a dictionary, along with their value: 


function get_values(node)
    name=Symbol(get(attributes(node),"name",-1))
    value=parse(Float64,(node[3][1]).value)
    return (name,value)
end
function add_parameters(node)
    cdrns=children(node)
    for i=(tables_ind+1):len
        (name,value)=get_values(node[i])
        _params[name] = value
    end
end



#now the init values: 

function get_init_value(node)
    try
        (name,value)= get_values(node)
        return (name,value)
    catch 
        name=Symbol(get(attributes(node),"name",-1))
        value_name=Symbol(node[3][1].value)
        value=get(_params,value_name,-1)
        return(name,value)
    end
end


function add_inits(node)
    cdrns=children(node)
    for i=1:stocks_ind
        (name,value)= get_init_value(node[i])
        _inits[name] = value 
    end
end

#now, let's write a small parser to parse the string of vensim equations into julia code :
#firszt a lexer tokenizing the string:


_word_separators=Vector{String}(["/","-","+","*","^","(",")",",","<",">","=","!","[","]","{","}"," ","\r","\n","\t"])

_tokenized_ws=Vector{String}(["DIV","MINUS","PLUS","TIME","POW","LP","RP","COMMA","LT","GT","EQUAL","NOT","LB","RB","LCB","RCB"])
_keywords=Vector{String}(["EXP","LOG","GAME","if_then_else","SMOOTHi","STEP","MAX","MIN","LN","SMOOTH","ABS","COS","ARCCOS","SIN","ARCSIN","TAN","ARCTAN",
"GAMMA_LN", "MODULO","RAMP",":AND:",":OR:"
])
#this vector can be augmented to add more functions to translate more models; for now it only contains then one necessary to make the "DICE" model work
function is_in(x,l)
    len=length(l)
    for i=1:len 
        y=l[i]
        if x==y
            return i
        end
    end
    return -1
end 

function string_separator(s)
    len=length(s)
    separating_inds=Vector{Int}([])
    separated_string=Vector{String}([])
    c=1
    for i=1:len 
        x=s[i:i]
        if is_in(x,_word_separators)>-1 
            push!(separating_inds,i)
        end
    end
    for j in separating_inds
        push!(separated_string,s[c:j-1])
        push!(separated_string,s[j:j])
        c=j+1
    end
    push!(separated_string,s[c:len])
    return separated_string
end

function Tokenize_s(s)
    if s==""
        return ("BLANK","")
    end
    i1=is_in(s,_word_separators)
    i2=is_in(s,_keywords)
    if i1 >-1 
        if i1>=16 
            return ("BLANK","")
        else
            return (_tokenized_ws[i1],"")
        end
    elseif i2>0
        if i2==4
            return ("IFTHENELSE","")
        else
            return (_keywords[i2],"")
        end
    else
        name=Symbol(s)
        if get(_tables,name,-1) != -1 
            return ("TABLE",s)
        else
            if s=="Time"
                return ("IDENT","t")
            else
                return ("IDENT",s)
            end
        end
    end
end

function Tokenize(sl)
    tsl=Vector{Tuple{String,String}}()
    for s in sl 
        token,data=Tokenize_s(s)
        if token != "BLANK"
            push!(tsl,(token,data))
        end
    end
    return tsl
end

function parsing_prep(s)
    sl=string_separator(s)
    tsl=Tokenize(sl)
    return tsl
end


_keywords2=Vector{String}(["EXP","LOG","GAME","IFTHENELSE","SMOOTH","SMOOTHi","STEP","MAX","MIN","LN","ABS","TABLE","COS","ARCCOS","SIN","ARCSIN","TAN","ARCTAN",
"GAMMA_LN", "MODULO","RAMP",":AND:",":OR:"


]) #keywords, but if_then_else is called IFTHENELSE to match other tokens. this may happen to othe functions added later on.
_one_arg_fcts=Vector{String}(["EXP","LN","GAME","TABLE","COS","ARCCOS","SIN","ARCSIN","TAN","ARCTAN",
"GAMMA_LN"])
_two_arg_fcts=Vector{String}(["MAX","LOG","MIN","STEP","SMOOTH","MODULO"])
_three_arg_fcts=Vector{String}(["IFTHENELSE","SMOOTHi"])
#depending on the number of arguments, function will be parsed differently. 



function is_in(x,l)
    len=length(l)
    for i=1:len 
        y=l[i]
        if x==y
            return i
        end
    end
    return -1
end 


struct AstNode
    token::String
    data::String
    children::Vector{AstNode}
    AstNode(token::String,data::String,children::Vector{AstNode}=AstNode[]) = new(token,data,children)
end


_make_node(token::String,data::String) = AstNode(token,data)
_make_node(token::String,data::String,children::Vector{AstNode}) = AstNode(token,data,children)

function node_convert(tsl) 
    nl=Vector{AstNode}()
    for x in tsl 
        token,data=x
        n=_make_node(token,data)
        push!(nl,n)
    end
    return nl
end

function sub_detect_fstpass(ns)
    #parentheses
    ignore=0
    pass=0
    sub_start=0
    sub_end=0
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token=n.token
        if is_in(token,_keywords2)>0
            pass=1
            ignore=ignore+1
        elseif pass==1 && token=="LP"
            pass=0
        elseif pass==0 && token =="LP"
            sub_start=i
            ignore=0
        elseif ignore>0 && token =="RP"
            ignore=ignore-1
        elseif ignore==0 && token == "RP"
            sub_end=i
            return (sub_start,sub_end)
        end
    end
    return (-1,-1)
end



function sub_detect_sndpass(ns)
    #one argument functions
    sub_start=0
    sub_end=0
    ignore=0
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,children=n.token,n.children
        if is_in(token,_one_arg_fcts)>0 && children == AstNode[]
            sub_start=i
            ignore=0
        elseif token =="RP" && ignore==0
            sub_end=i
            return (sub_start,sub_end)
        elseif is_in(token,_keywords2)>0
            ignore = ignore + 1
        elseif token=="RP"
            ignore = ignore -1 
        end
    end
    return (-1,-1)
end

function sub_detect_thirdpass(ns)
    sub_start1=0
    sub_start2=0
    sub_end1=0
    sub_end2=0
    ignore=0
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data
        if is_in(token,_two_arg_fcts)>0 && n.children == AstNode[] && sub_start1 == 0
            sub_start1=i
            ignore=0
        elseif token =="COMMA" && ignore == 0
            sub_end1=i
            sub_start2=i+1
        elseif token =="RP" && ignore==0
            sub_end2=i
            return (sub_start1,sub_end1,sub_start2,sub_end2)
        elseif is_in(token,_two_arg_fcts)>0 || is_in(token,_three_arg_fcts)>0
            ignore = ignore + 1
        elseif token=="RP"
            ignore = ignore -1 
        end
    end
    return (-1,-1,-1,-1)
end

function sub_detect_fourthpass(ns)
    #3arguements functions
    sub_start1=0
    sub_start2=0
    sub_start3=0
    sub_end1=0
    sub_end2=0
    sub_end3=0
    comma=0
    ignore=0
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data
        if is_in(token,_three_arg_fcts)>0 && n.children == AstNode[] && sub_start1 == 0
            sub_start1=i
            ignore=0
        elseif token =="COMMA" && ignore == 0
            if comma==0
                sub_end1=i
                sub_start2=i+1
                comma=1
            else
                sub_end2=i
                sub_start3=i+1
            end
        elseif token =="RP" && ignore==0
            sub_end3=i
            return (sub_start1,sub_end1,sub_start2,sub_end2,sub_start3,sub_end3)
        elseif is_in(token,_three_arg_fcts)>0
            ignore = ignore + 1
        elseif token=="RP"
            ignore = ignore -1 
        end
    end
    return (-1,-1,-1,-1,-1,-1)
end

function sub_detect_fifthpass(ns)
    #detect logic 
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data 
        if ( token=="EQUAL" || token=="LT" || token == "GT" || token == ":AND:"|| token == ":OR:") && n.children == AstNode[]
            return (i)
        end
    end
    return (-1)
end

function sub_detect_sixthpass(ns)
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data 
        if (token=="PLUS" || token =="MINUS") && n.children == AstNode[]
            return (i)
        end
    end
    return (-1)
end
function sub_detect_seventhpass(ns)
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data 
        if (token=="TIME" || token =="DIV" ) && n.children == AstNode[]
            return (i)
        end
    end
    return -1
end
function sub_detect_eighthpass(ns)
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data 
        if token=="POW"   && n.children == AstNode[]
            return (i)
        end
    end
    return -1
end

#the parser will work like this: 
#first find the parentheses, then parse the inside of them
#if the token list doesn't have parantheseses, find the functions, and parse their arguments. 
#once all of these have been found, we parse the rest using simple operations priority. 
#this means the string will be traversed a lot of time, but as they are of small size, the function execute decently fast.

function parser(nl)
    #first pass
    sub_start,sub_end=sub_detect_fstpass(nl)
    while sub_start>0
        parsed_node=parser(nl[sub_start+1:sub_end-1])
        len=length(nl)
        nl=vcat(nl[1:sub_start-1],parsed_node,nl[sub_end+1:len])
        sub_start,sub_end=sub_detect_fstpass(nl)      
    end  
    #snd pass 
    sub_start,sub_end=sub_detect_sndpass(nl)
    while sub_start>0
        token,data=nl[sub_start].token,nl[sub_start].data
        parsed_node=parser(nl[sub_start+2:sub_end-1])
        len=length(nl)
        new_node=_make_node(token,data,parsed_node)
        nl=vcat(nl[1:sub_start-1],[new_node],nl[sub_end+1:len])
        sub_start,sub_end=sub_detect_sndpass(nl)
    end
    #third pass 
    
    sub_start1,sub_end1,sub_start2,sub_end2=sub_detect_thirdpass(nl)
    while sub_start1>0
        token,data=nl[sub_start1].token,nl[sub_start1].data
        parsed_node1=parser(nl[sub_start1+2:sub_end1-1])
        parsed_node2=parser(nl[sub_start2:sub_end2-1])
        len=length(nl)
        new_node=_make_node(token,data,vcat(parsed_node1,parsed_node2))
        nl=vcat(nl[1:sub_start1-1],[new_node],nl[sub_end2+1:len])
        sub_start1,sub_end1,sub_start2,sub_end2=sub_detect_thirdpass(nl)    
    end
    #fourth pass
    sub_start1,sub_end1,sub_start2,sub_end2,sub_start3,sub_end3=sub_detect_fourthpass(nl)
    while sub_start1>0
        token,data=nl[sub_start1].token,nl[sub_start1].data
        parsed_node1=parser(nl[sub_start1+2:sub_end1-1])
        parsed_node2=parser(nl[sub_start2:sub_end2-1])
        parsed_node3=parser(nl[sub_start3:sub_end3-1])
        len=length(nl)
        new_node=_make_node(token,data,vcat(parsed_node1,parsed_node2,parsed_node3))
        nl=vcat(nl[1:sub_start1-1],[new_node],nl[sub_end3+1:len])
        sub_start1,sub_end1,sub_start2,sub_end2,sub_start3,sub_end3=sub_detect_fourthpass(nl)        
    end
    #fifth pass 
    sign_pos=sub_detect_fifthpass(nl)
    if sign_pos>0
        token,data=nl[sign_pos].token,nl[sign_pos].data
        len=length(nl)
        lefthand=parser(nl[1:sign_pos-1])
        righthand=parser(nl[sign_pos+1:len])
        new_node=_make_node(token,data,vcat(lefthand,righthand))
        return ([new_node])
    end
    #sixth pass
    sign_pos=sub_detect_sixthpass(nl)
    if sign_pos>0
        token,data=nl[sign_pos].token,nl[sign_pos].data
        len=length(nl)
        lefthand=parser(nl[1:sign_pos-1])
        righthand=parser(nl[sign_pos+1:len])
        if lefthand == AstNode[]
            neg=_make_node("NEG",data,[nl[sign_pos+1]])
            nl=vcat(nl[1:sign_pos-1],[neg],nl[sign_pos+2:length(nl)])
            return (parser(nl))
        end
        new_node=_make_node(token,data,vcat(lefthand,righthand))
        return ([new_node])
    end
    #seventh pass
    sign_pos=sub_detect_seventhpass(nl)
    if sign_pos>0
        token,data=nl[sign_pos].token,nl[sign_pos].data
        len=length(nl)
        lefthand=parser(nl[1:sign_pos-1])
        righthand=parser(nl[sign_pos+1:len])
        new_node=_make_node(token,data,vcat(lefthand,righthand))
        return ([new_node])
    end
    #eighth pass
    sign_pos=sub_detect_eighthpass(nl)
    if sign_pos>0
        token,data=nl[sign_pos].token,nl[sign_pos].data
        len=length(nl)
        lefthand=parser(nl[1:sign_pos-1])
        righthand=parser(nl[sign_pos+1:len])
        new_node=_make_node(token,data,vcat(lefthand,righthand))
        return ([new_node])
    end
    #if none of those matched, then it is an ident: 
    if length(nl)==1 && nl[1].token =="IDENT"
        return ([_make_node(nl[1].token,nl[1].data)])
    end

    return nl
end

#now that we have an AST of the eqn, we need to translate it into another string, but this time respecting julia syntax: 

function matching(name,ast)
    t,d,c=ast.token,ast.data,ast.children

    if t == "PLUS"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"+"*rh)
    end
    if t == "MINUS"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"-"*rh)
    end
    if t == "TIME"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"*"*rh)
    end
    if t == "DIV"
        #println("atteinddiv")
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"/"*rh)
    end
    if t == "NEG"
        rh="("*matching(name,c[1])*")"
        return ("-"*rh)
    end
    if t == "POW"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"^"*rh)
    end
    if t == "LT"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"<"*rh)
    end
    if t == "GT"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*">"*rh)
    end
    if t == "EQUAL"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"=="*rh)
    end
    if t == ":AND:"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"&&"*rh)
    end
    if t == ":OR:"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (lh*"||"*rh)
    end
    if t == "LN"
        #println("atteindln")
        c="("*matching(name,c[1])*")"
        return ("log"*c)
    end
    if t == "EXP"
        #println("atteindln")
        c="("*matching(name,c[1])*")"
        return ("exp"*c)
    end
    if t == "GAME"
        #not implemented yet, supposed to change value interacitvely with user input
        c="("*matching(name,c[1])*")"
        return (c)
    end
    if t == "ABS"
        c="("*matching(name,c[1])*")"
        return  ("abs"*c)
    end
    if t == "COS"
        c="("*matching(name,c[1])*")"
        return "cos"*c
    end
    if t == "ARCCOS"
        c="("*matching(name,c[1])*")"
        return "arccos"*c
    end
    if t == "SIN"
        c="("*matching(name,c[1])*")"
        return "sin"*c
    end
    if t == "ARCSIN"
        c="("*matching(name,c[1])*")"
        return "arcsin"*c
    end
    if t == "TAN"
        c="("*matching(name,c[1])*")"
        return "tan"*c
    end
    if t == "ARCTAN"
        c="("*matching(name,c[1])*")"
        return "arctan"*c
    end
    if t == "COSH"
        c="("*matching(name,c[1])*")"
        return "cosh"*c
    end
    if t == "GAMMA_LN"
        c="("*matching(name,c[1])*")"
        return ("loggamma"*c)
    end
    if t == "MAX"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return ("max("*lh*","*rh*")")
    end
    if t == "MIN"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return ("min("*lh*","*rh*")")
    end
    if t == "LOG"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return ("log("*rh*","*lh*")")
    end
    if t == "MODULO"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return (rh*"%"*lh)
    end
    if t == "STEP"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        return ("IfElse.ifelse( t<"*rh*",0,"*lh*")")
    end
    if t =="SMOOTH"
        lh="("*matching(name,c[1])*")"
        rh="("*matching(name,c[2])*")"
        smn="TEMPVARSMOOTHED_"*name
        smn2="TEMPVAR_"*name
        push!(_decl_vars,"@variables "*smn*"(t) = "*smn2*" [description = \""*smn*", created by the \\\"SMOOTH\\\" function or an afiliate.\"]\n")
        push!(_decl_vars,"@variables "*smn2*"(t) = 42 [description = \""*smn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_eqns,"\t"*smn2*" ~ "*lh*"\n")
        push!(_decl_eqns,"\tD("*smn*") ~ ("*lh *"-"*smn*") /"*rh*"\n")
        return (smn)

    end
    if t == "SMOOTHi"
        fm="("*matching(name,c[1])*")"
        sm="("*matching(name,c[2])*")"
        tm="("*matching(name,c[3])*")"
        smn="TEMPVARSMOOTHED_"*name
        smn2="TEMPVAR_"*name
        str="("*fm *"-"*smn*") /"*sm
        push!(_decl_vars,"@variables "*smn*"(t) = "*smn2*" [description = \""*smn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_vars,"@variables "*smn2*"(t) = 42 [description = \""*smn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_eqns,"\t"*smn2*" ~ "*tm*"\n")
        push!(_decl_eqns,"\tD("*smn*") ~ "* str*"\n")
        return (smn)
        
    end
    if t =="IFTHENELSE" 
        fm=matching(name,c[1])
        sm="("*matching(name,c[2])*")"
        tm="("*matching(name,c[3])*")"
        return ("IfElse.ifelse("*fm*","*sm*","*tm*")")
    end
    if t == "TABLE"
        c1="("*matching(name,c[1])*")"
        return (d*"("*c1*")")
    end
    if t == "IDENT"
        #println("atteindident")
        return d
    end
end




function eqn_maker!(name,eqn)
    tsl=parsing_prep(eqn)
    nl=node_convert(tsl)
    ast=parser(nl)[1]
    str=matching(name,ast)
    push!(_decl_eqns, "\t"*name*" ~ "*str*"\n")
    push!(_decl_vars, "@variables "*name*"(t)  [description = \""*name*"\"]\n")
end

function eqn_decls(stocks_ind,eqn_ind,root)
    for i=1:stocks_ind
        node=root[3][1][i]
        n=length(node)
        name=get(attributes(node),"name",-1)
        if n>3
            if node[4].tag=="inflow"
                inf=replace(node[4][1].value,Pair(" ","_"))
                if n==5
                    outf=replace(node[5][1].value,Pair(" ","_"))
                    eqn="\tD("*name*") ~ "* inf*"-"*outf*"\n"
                    push!(_decl_eqns,eqn)
                else
                    eqn="\tD("*name*") ~ "* inf*"\n"
                    push!(_decl_eqns,eqn)
                end
            else 
                outf=replace(node[4][1].value,Pair(" ","_"))
                eqn="\tD("*name*") ~ -"* outf*"\n"
                push!(_decl_eqns,eqn)
            end
        end
    end
    for i=(stocks_ind+1):eqn_ind
        name=get(attributes(root[3][1][i]),"name",-1)
        eqn=root[3][1][i][3][1].value
        eqn_maker!(name,eqn)
    end
end

#now, let's make the tables:


function table_maker(eqn_ind,tables_ind,root)
    for i=eqn_ind+1:tables_ind
        name=Symbol(get(attributes(root[3][1][i]),"name",-1))
        reg=r"\w+.\w+"
        tab=root[3][1][i][3][2][1].value
        vall=Vector{Float64}()
        for s in eachmatch(reg,tab)
            v=parse(Float64,s.match)
            push!(vall,v)
        end
        valt=tuple(vall...)
        _tables[name]=valt
        tabr=root[3][1][i][3][1][1].value
        vall2=Vector{Float64}()
        for s in eachmatch(reg,tabr)
            v=parse(Float64,s.match)
            push!(vall2,v)
        end
        valt2=tuple(vall2...)
        _ranges[name]=valt2
    end
end


function file_writer(_params,_inits,_tables,_ranges,_decl_vars,_decl_eqns,root)
    reg=r"=\s*\w*"
    dt=match(reg,root[2][3][1].value).match
    method=get(attributes(root[2]),"method",-1)
    base_str= 
    "
using IfElse
using SpecialFunctions
using ModelingToolkit
using DifferentialEquations

#variables and parameters of the model (the variable/parameter name \"t\" is forbiden)
@variables t
D = Differential(t)
@parameters "*root[2][3][1].value*" [description = \"TIME_STEP, the dt of the model\"]\n"


    for (k,v) in _params 
        str="@parameters "*string(k)*" = "*string(v)*" [description = \""*string(k)*"\"]\n"
        base_str = base_str * str
    end

    for (k,v) in _inits 
        str="@variables "*string(k)*"(t) = "*string(v)*" [description = \""*string(k)*"\"]\n"
        base_str = base_str * str        
    end

    for str in _decl_vars 
        base_str = base_str * str
    end

    base_str= base_str *" 
    
#définition des tables:\n\n"
    for (k,v) in _tables
        tbl_str=string(k)*"_base =Vector{Float64}(["
        for vl in v 
            tbl_str=tbl_str*string(vl)*","
        end
        tbl_str=tbl_str*"])\n"
        tbl_str=tbl_str*string(k)*"_ranges = Vector{Float64}(["
        rangev=_ranges[k]
        for rv in rangev 
            tbl_str=tbl_str*string(rv)*","
        end
        tbl_str=tbl_str*"])\n"*string(k)*"(t)=LinearInterpolation("*string(k)*"_base,"*string(k)*"_ranges)(t)\n@register_symbolic "*string(k)*"(t)\n\n"
        base_str=base_str*tbl_str
    end

    base_str= base_str*

"#définition des equations:
eqs = [
    "

    for str in _decl_eqns 
        base_str= base_str *str
    end
    base_str = base_str *"
    
]
    
#il faut maintenant définir le solveur: 
    
@named sys= ODESystem(eqs)
sys= structural_simplify(sys)
prob= ODEProblem(sys,[],("*root[2][1][1].value*","*root[2][2][1].value*"), solver="*method*", dt"*dt*", dtmax"*dt*")
solved=solve(prob)
using Plots 

#plot(solved)
    "
end


function file_generation(filepath)
    filename,doc,root,len=setup(filepath)    
    (stocks_ind,eqn_ind,tables_ind)=ind(root[3][1])  
    _params = Dict{Symbol,Float64}()
    getparameters() = copy(_params)
    add_parameters(root[3][1])   
    _inits = Dict{Symbol,Float64}() 
    getinitialisations()= copy(_inits) 
    add_inits(root[3][1])   
    _decl_vars=Vector{String}()
    _decl_eqns=Vector{String}() 
    _tables = Dict{Symbol,Tuple{Vararg{Float64}}}()
    _ranges = Dict{Symbol,Tuple{Vararg{Float64}}}()
    table_maker(eqn_ind,tables_ind,root)
    eqn_decls(stocks_ind, eqn_ind, root)
    return (file_writer(_params,_inits,_tables,_ranges,_decl_vars,_decl_eqns,root))
end

##
print(file_generation(filepath))