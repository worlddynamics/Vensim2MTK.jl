using XML

function setup(filepath)
    filename=filepath
    doc=read(filename,Node)
    root=doc[end]
    len = size(children(root[3][1]),1)
    return filename,doc,root,len
end


function is_a_table(node)
    tag(node[3])=="gf" 
end

function is_a_param(node)
    try 
        parse(Float64,node[3][1].value)
        return true
    catch 
        return false
    end
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
        elseif stocks_ind>0 && eqn_ind==0 && (is_a_table(child) || is_a_param(child))
            eqn_ind = counter
            counter = counter+1
            if is_a_param(child)
                return (stocks_ind,eqn_ind,0,eqn_ind+1)
            end
        elseif eqn_ind>0 && !is_a_table(child)
            tables_ind=counter
            return (stocks_ind,eqn_ind,tables_ind,tables_ind+1)
        else 
            counter = counter + 1
        end
    end
end

function get_values(node)
    name=Symbol(get(attributes(node),"name",-1))
    value=parse(Float64,(node[3][1]).value)
    return (name,value)
end

function add_parameters!(node,params_ind,len,_params)
    for i=(params_ind):len
        (name,value)=get_values(node[i])
        _params[name] = value
    end
end


function get_init_value(node,_decl_eqns,_decl_vars,_tables,_params)
    name=Symbol(get(attributes(node),"name",-1))
    eqn=(node[3][1].value)
    tsl=parsing_prep(eqn,_tables)
    tsl=param_passing(tsl,_params)
    nl=node_convert(tsl)
    ast=parser(nl)[1]
    str=matching(name,ast,_decl_eqns,_decl_vars,_tables)
    return(name,str)
end


function add_inits!(node,stocks_ind,_inits,_decl_eqns,_decl_vars,_tables,_params)
    for i=1:stocks_ind
        (name,value)= get_init_value(node[i],_decl_eqns,_decl_vars,_tables,_params)
        _inits[name] = value 
    end
end

const _word_separators=("/","-","+","*","^","(",")",",","<",">","=","!","[","]","{","}"," ","\r","\n","\t")
const _tokenized_ws=("DIV","MINUS","PLUS","TIME","POW","LP","RP","COMMA","LT","GT","EQUAL","NOT","LB","RB","LCB","RCB")
const _keywords=("EXP","LOG","GAME","if_then_else","SMOOTHi","STEP","MAX","MIN","LN","SMOOTH","ABS","COS","ARCCOS","SIN","ARCSIN","TAN","ARCTAN",
"GAMMA_LN", "MODULO","RAMP",":AND:",":OR:","SMOOTH3","PULSE","SMOOTH3i","DELAY1","DELAY1I","SQRT"
)

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

function Tokenize_s(s,_tables)
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

function Tokenize(sl,_tables)
    tsl=Vector{Tuple{String,String}}()
    for s in sl 
        token,data=Tokenize_s(s,_tables)
        if token != "BLANK"
            push!(tsl,(token,data))
        end
    end
    return tsl
end

function parsing_prep(s,_tables)
    sl=string_separator(s)
    tsl=Tokenize(sl,_tables)
    return tsl
end

function param_passing(tsl,_params)
    for i=1:(length(tsl)) 
        (t,d)=tsl[i]
        value_name=Symbol(d)
        value=get(_params,value_name,"no_value")
        if t =="IDENT" && value != "no_value"
            d=string(value)
            tsl[i]=(t,d)
        end
    end
    return(tsl)
end
const _keywords2=("EXP","LOG","GAME","IFTHENELSE","SMOOTH","SMOOTHi","STEP","MAX","MIN","LN","ABS","TABLE","COS","ARCCOS","SIN","ARCSIN","TAN","ARCTAN",
"GAMMA_LN", "MODULO","RAMP",":AND:",":OR:","SMOOTH3","PULSE","SMOOTH3i","DELAY1","DELAY1I","SQRT"


)
const _one_arg_fcts=("EXP","LN","GAME","TABLE","COS","ARCCOS","SIN","ARCSIN","TAN","ARCTAN",
"GAMMA_LN","SQRT")
const _two_arg_fcts=("MAX","LOG","MIN","STEP","SMOOTH","MODULO","SMOOTH3","PULSE","DELAY1")
const _three_arg_fcts=("IFTHENELSE","SMOOTHi","RAMP","DELAY1I")


mutable struct AstNode
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
    sub = (start = [0, 0], stop = [0, 0])
    ignore=0
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data
        if is_in(token,_two_arg_fcts)>0 && n.children == AstNode[] && sub.start[1] == 0
            sub.start[1]=i
            ignore=0
        elseif token =="COMMA" && ignore == 0
            sub.stop[1]=i
            sub.start[2]=i+1
        elseif token =="RP" && ignore==0
            sub.stop[2]=i
            return (sub.start[1],sub.stop[1],sub.start[2],sub.stop[2])
        elseif is_in(token,_two_arg_fcts)>0 || is_in(token,_three_arg_fcts)>0
            ignore = ignore + 1
        elseif token=="RP"
            ignore = ignore -1 
        end
    end
    return (-1,-1,-1,-1)
end

function sub_detect_fourthpass(ns)
    sub = (start = [0, 0, 0], stop = [0, 0, 0])
    comma=0
    ignore=0
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data
        if is_in(token,_three_arg_fcts)>0 && n.children == AstNode[] && sub.start[1] == 0
            sub.start[1]=i
            ignore=0
        elseif token =="COMMA" && ignore == 0
            if comma==0
                sub.stop[1]=i
                sub.start[2]=i+1
                comma=1
            else
                sub.stop[2]=i
                sub.start[3]=i+1
            end
        elseif token =="RP" && ignore==0
            sub.stop[3]=i
            return (sub.start[1],sub.stop[1],sub.start[2],sub.stop[2],sub.start[3],sub.stop[3])
        elseif is_in(token,_three_arg_fcts)>0
            ignore = ignore + 1
        elseif token=="RP"
            ignore = ignore -1 
        end
    end
    return (-1,-1,-1,-1,-1,-1)
end

function sub_detect_fifthpass(ns)
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data 
        if (  token == ":AND:"|| token == ":OR:") && n.children == AstNode[]
            return (i)
        end
    end
    return (-1)
end

function sub_detect_fifthpass_bis(ns)
    len=length(ns)
    for i=1:len 
        n=ns[i]
        token,data=n.token,n.data 
        if ( token=="EQUAL" || token=="LT" || token == "GT" ) && n.children == AstNode[]
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

function fifth_seventh_eighth_pass(sign_pos,nl)
    token,data=nl[sign_pos].token,nl[sign_pos].data
    len=length(nl)
    lefthand=parser(nl[1:sign_pos-1])
    righthand=parser(nl[sign_pos+1:len])
    new_node=_make_node(token,data,vcat(lefthand,righthand))
    return ([new_node])
end


function parser(nl)
    sub_start,sub_end=sub_detect_fstpass(nl)
    while sub_start>0
        parsed_node=parser(nl[sub_start+1:sub_end-1])
        len=length(nl)
        nl=vcat(nl[1:sub_start-1],parsed_node,nl[sub_end+1:len])
        sub_start,sub_end=sub_detect_fstpass(nl)      
    end  
    sub_start,sub_end=sub_detect_sndpass(nl)
    while sub_start>0
        token,data=nl[sub_start].token,nl[sub_start].data
        parsed_node=parser(nl[sub_start+2:sub_end-1])
        len=length(nl)
        new_node=_make_node(token,data,parsed_node)
        nl=vcat(nl[1:sub_start-1],[new_node],nl[sub_end+1:len])
        sub_start,sub_end=sub_detect_sndpass(nl)
    end
    
    sub_start1,sub_end1,sub_start2,sub_end2=sub_detect_thirdpass(nl)
    while sub_start1>0
        token,data=nl[sub_start1].token,nl[sub_start1].data
        parsed_node=(parser(nl[sub_start1+2:sub_end1-1]),parser(nl[sub_start2:sub_end2-1]))
        len=length(nl)
        new_node=_make_node(token,data,vcat(parsed_node[1],parsed_node[2]))
        nl=vcat(nl[1:sub_start1-1],[new_node],nl[sub_end2+1:len])
        sub_start1,sub_end1,sub_start2,sub_end2=sub_detect_thirdpass(nl)    
    end
    sub_start1,sub_end1,sub_start2,sub_end2,sub_start3,sub_end3=sub_detect_fourthpass(nl)
    while sub_start1>0
        token,data=nl[sub_start1].token,nl[sub_start1].data
        parsed_node=(parser(nl[sub_start1+2:sub_end1-1]),parser(nl[sub_start2:sub_end2-1]),parser(nl[sub_start3:sub_end3-1]))
        len=length(nl)
        new_node=_make_node(token,data,vcat(parsed_node[1],parsed_node[2],parsed_node[3]))
        nl=vcat(nl[1:sub_start1-1],[new_node],nl[sub_end3+1:len])
        sub_start1,sub_end1,sub_start2,sub_end2,sub_start3,sub_end3=sub_detect_fourthpass(nl)        
    end
    sign_pos=sub_detect_fifthpass(nl)
    if sign_pos>0
        return fifth_seventh_eighth_pass(sign_pos,nl)
    end

    sign_pos=sub_detect_fifthpass_bis(nl)
    if sign_pos>0
        return fifth_seventh_eighth_pass(sign_pos,nl)
    end
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
    sign_pos=sub_detect_seventhpass(nl)
    if sign_pos>0
        return fifth_seventh_eighth_pass(sign_pos,nl)
    end
    sign_pos=sub_detect_eighthpass(nl)
    if sign_pos>0
        return fifth_seventh_eighth_pass(sign_pos,nl)
    end
    if length(nl)==1 && nl[1].token =="IDENT"
        return ([_make_node(nl[1].token,nl[1].data)])
    end

    return nl
end

function ifelse_seperate!(ast)
    t,d,c=ast.token,ast.data,ast.children
    if t=="IFTHENELSE"
        cond=c[1]
        tc,dc,cc=cond.token,cond.data,cond.children
        if tc == ":AND:"
            newchildren=[cc[2],c[2],c[3]]
            newnode=_make_node("IFTHENELSE","",newchildren)
            c[1]=cc[1]
            c[2]=newnode
        end
        if tc == ":OR:"
            newchildren=[cc[2],c[2],c[3]]
            newnode=_make_node("IFTHENELSE","",newchildren)
            c[1]=cc[1]
            c[3]=newnode
        end
    end
    for as in c
        ifelse_seperate!(as)
    end
end

function matching(name,ast,_decl_eqns,_decl_vars,_tables)
    t,d,c=ast.token,ast.data,ast.children

    t == "PLUS" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") + (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "MINUS" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") - (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "TIME" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") * (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "DIV" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") / (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "NEG" && return "- (" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "POW" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") ^ (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "LT" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") < (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "GT" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") > (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "EQUAL" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") == (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == ":AND:" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") && (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == ":OR:" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") || (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "LN" && return " log(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "EXP" && return " exp(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "SQRT" && return " sqrt(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "GAME" && return " (" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "ABS" && return " abs(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "COS" && return " cos(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "ARCCOS" && return " arccos(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "SIN" && return " sin(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "ARCSIN" && return " arcsin(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "TAN" && return " tan(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "ARCTAN" && return " arctan(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "COSH" && return " cosh(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "GAMMA_LN" && return " loggamma(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ")"
    t == "MAX" && return "max((" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") , (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * "))"
    t == "MIN" && return "min((" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") , (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * "))"
    t == "LOG" && return "max((" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ") , (" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * "))"
    t == "MODULO" && return "(" * matching(name,c[1],_decl_eqns,_decl_vars,_tables) * ") % (" * matching(name,c[2],_decl_eqns,_decl_vars,_tables) * ")"
    t == "STEP"&& return ("IfElse.ifelse( t<"*"("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"*",0,"*"("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"*")")
    t == "TABLE" && return (d*"("*"("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"*")")
    t == "IDENT" && return d
    t =="IFTHENELSE" && return ("IfElse.ifelse("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*","*"("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"*","*"("*matching(name,c[3],_decl_eqns,_decl_vars,_tables)*")"*")")
    t =="PULSE" && return ("IfElse.ifelse("*"t_plus > "*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*", IfElse.ifelse(t_plus < ("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*" + "*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*"), 1.0, 0.0),0.0)")
    t ==":AND:" 
    if t == "RAMP"
        fm="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        sm="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        tm="("*matching(name,c[3],_decl_eqns,_decl_vars,_tables)*")"
        return ("IfElse.ifelse( t > "*sm*",IfElse.ifelse( t < "*tm*", "*fm*"* (t -"*sm*"), "*fm*"* ("*tm*" - "*sm*")),0"
    )
    end
    if t =="SMOOTH"
        lh="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        rh="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        smn="TEMPVARSMOOTHED_"*name
        smn2="TEMPVAR_"*name
        push!(_decl_vars,"@variables "*smn2*"(t) = 42 [description = \""*smn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*smn*"(t) = "*smn2*" [description = \""*smn*", created by the \\\"SMOOTH\\\" function or an afiliate.\"]\n")
        push!(_decl_eqns,"\t"*smn2*" ~ "*lh*"\n")
        push!(_decl_eqns,"\tD("*smn*") ~ ("*lh *"-"*smn*") /"*rh*"\n")
        return (smn)
    end
    if t == "DELAY1"
        lh="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        rh="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        dln="TEMPVARDELAYED_"*name
        dln2="TEMPVAR_"*name
        push!(_decl_vars,"@variables "*dln2*"(t) = 42 [description = \""*smn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*dln*"(t) = "*dln2*" [description = \""*smn*", created by the \\\"SMOOTH\\\" function or an afiliate.\"]\n")
        push!(_decl_eqns,"\t"*dln2*" ~ "*lh*"*"*rh*"\n")
        push!(_decl_eqns,"\tD("*dln*") ~ ("*lh *"-"*dln*") \n")
        return (dln*"/"*rh)
    end
    if t == "DELAY1I"
        lh="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        rh="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        tm="("*matching(name,c[3],_decl_eqns,_decl_vars,_tables)*")"
        dln="TEMPVARDELAYED_"*name
        dln2="TEMPVAR_"*name
        push!(_decl_vars,"@variables "*dln2*"(t) = 42 [description = \""*smn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*dln*"(t) = "*dln2*" [description = \""*smn*", created by the \\\"SMOOTH\\\" function or an afiliate.\"]\n")
        push!(_decl_eqns,"\t"*dln2*" ~ "*tm*"*"*rh*"\n")
        push!(_decl_eqns,"\tD("*dln*") ~ ("*lh *"-"*dln*") \n")
        return (smn*"/"*rh)
    end    

    if t == "SMOOTHi"
        fm="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        sm="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        tm="("*matching(name,c[3],_decl_eqns,_decl_vars,_tables)*")"
        smn="TEMPVARSMOOTHED_"*name
        smn2="TEMPVAR_"*name
        str="("*fm *"-"*smn*") /"*sm
        push!(_decl_vars,"@variables "*smn2*"(t) = 42 [description = \""*smn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*smn*"(t) = "*smn2*" [description = \""*smn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_eqns,"\t"*smn2*" ~ "*tm*"\n")
        push!(_decl_eqns,"\tD("*smn*") ~ "* str*"\n")
        return (smn)       
    end
    if t =="SMOOTH3"
        lh="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        rh="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        dl="("*rh*"/3)"
        fsmn="TEMPVARSMOOTHED1_"*name
        ssmn="TEMPVARSMOOTHED2_"*name
        tsmn="TEMPVARSMOOTHED3_"*name
        fsmn2="TEMPVAR1_"*name
        ssmn2="TEMPVAR2_"*name
        tsmn2="TEMPVAR3_"*name
        lv1="("*lh*"-"*fsmn*") /"*dl
        lv2="("*fsmn*"-"*ssmn*") /"*dl
        str="("*ssmn*"-"*tsmn*") /"*dl
        push!(_decl_vars,"@variables "*fsmn2*"(t) = 42 [description = \""*fsmn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*ssmn2*"(t) = 42 [description = \""*ssmn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*tsmn2*"(t) = 42 [description = \""*tsmn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*fsmn*"(t) = "*fsmn2*" [description = \""*fsmn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_vars,"@variables "*ssmn*"(t) = "*ssmn2*" [description = \""*ssmn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_vars,"@variables "*tsmn*"(t) = "*tsmn2*" [description = \""*tsmn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_eqns,"\t"*fsmn2*" ~ "*lh*"\n")
        push!(_decl_eqns,"\t"*ssmn2*" ~ "*lh*"\n")
        push!(_decl_eqns,"\t"*tsmn2*" ~ "*lh*"\n")
        push!(_decl_eqns,"\tD("*fsmn*") ~ "*lv1*"\n")
        push!(_decl_eqns,"\tD("*ssmn*") ~ "*lv2*"\n")
        push!(_decl_eqns,"\tD("*tsmn*") ~ "*str*"\n")
        return (tsmn)
    end    
    if t =="SMOOTH3i"
        lh="("*matching(name,c[1],_decl_eqns,_decl_vars,_tables)*")"
        rh="("*matching(name,c[2],_decl_eqns,_decl_vars,_tables)*")"
        tm="("*matching(name,c[3],_decl_eqns,_decl_vars,_tables)*")"
        dl="("*rh*"/3)"
        fsmn="TEMPVARSMOOTHED1_"*name
        ssmn="TEMPVARSMOOTHED2_"*name
        tsmn="TEMPVARSMOOTHED3_"*name
        fsmn2="TEMPVAR1_"*name
        ssmn2="TEMPVAR2_"*name
        tsmn2="TEMPVAR3_"*name
        lv1="("*lh*"-"*fsmn*") /"*dl
        lv2="("*fsmn*"-"*ssmn*") /"*dl
        str="("*ssmn*"-"*tsmn*") /"*dl
        push!(_decl_vars,"@variables "*fsmn2*"(t) = 42 [description = \""*fsmn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*ssmn2*"(t) = 42 [description = \""*ssmn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*tsmn2*"(t) = 42 [description = \""*tsmn2*", created by the \\\"SMOOTH\\\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution\"]\n")
        push!(_decl_vars,"@variables "*fsmn*"(t) = "*fsmn2*" [description = \""*fsmn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_vars,"@variables "*ssmn*"(t) = "*ssmn2*" [description = \""*ssmn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_vars,"@variables "*tsmn*"(t) = "*tsmn2*" [description = \""*tsmn*", created by the \\\"SMOOTH\\\" function or an afiliate\"]\n")
        push!(_decl_eqns,"\t"*fsmn2*" ~ "*tm*"\n")
        push!(_decl_eqns,"\t"*ssmn2*" ~ "*tm*"\n")
        push!(_decl_eqns,"\t"*tsmn2*" ~ "*tm*"\n")
        push!(_decl_eqns,"\tD("*fsmn*") ~ "*lv1*"\n")
        push!(_decl_eqns,"\tD("*ssmn*") ~ "*lv2*"\n")
        push!(_decl_eqns,"\tD("*tsmn*") ~ "*str*"\n")
        return (tsmn)
    end
end




function eqn_maker!(name,eqn,_decl_eqns,_decl_vars,_tables)
    tsl=parsing_prep(eqn,_tables)
    nl=node_convert(tsl)
    ast=parser(nl)[1]
    ifelse_seperate!(ast)
    str=matching(name,ast,_decl_eqns,_decl_vars,_tables)
    push!(_decl_eqns, "\t"*name*" ~ "*str*"\n")
    push!(_decl_vars, "@variables "*name*"(t)  [description = \""*name*"\"]\n")
end

function eqn_decls(stocks_ind,eqn_ind,root,_decl_eqns,_decl_vars,_tables)
    for i=1:stocks_ind
        node=root[3][1][i]
        name=get(attributes(node),"name",-1)
        cdrns=node.children 
        infs=Vector{String}()
        outfs=Vector{String}()
        for flow in cdrns
            flow.tag == "inflow" && push!(infs, replace(flow[1].value,Pair(" ","_")))
            flow.tag == "outflow" && push!(outfs, replace(flow[1].value,Pair(" ","_")))
        end
        ni=length(infs)
        no=length(outfs)
        inf=""
        outf=""
        if ni>0  inf=infs[1] end
        if no>0  outf=" - "*outfs[1] end
        for i=2:ni
            inf=inf*" + "*infs[i]
        end
        for i=2:no
            outf=outf*" - "*outfs[i]
        end
        push!(_decl_eqns, "\tD("*name*") ~ "*inf*outf*"\n")
    end
    for i=(stocks_ind+1):eqn_ind
        name=get(attributes(root[3][1][i]),"name",-1)
        eqn=root[3][1][i][3][1].value
        eqn_maker!(name,eqn,_decl_eqns,_decl_vars,_tables)
    end
end



function table_maker(eqn_ind,tables_ind,root,_tables,_ranges)
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


const file_preamble ="""
using IfElse
using SpecialFunctions
using ModelingToolkit
using DifferentialEquations

#variables and parameters of the model (the variable/parameter name \"t\" is forbiden)
@variables t
D = Differential(t)
@parameters """

const file_stop ="""
]
    
    
@named sys= ODESystem(eqs)
sys= structural_simplify(sys)
prob= ODEProblem(sys,[],("""

function file_writer(_params,_inits,_tables,_ranges,_decl_vars,_decl_eqns,root)
    reg=r"=\s*\w*.*\w*"
    dt=match(reg,root[2][3][1].value).match
    method=get(attributes(root[2]),"method",-1)
    base_str= file_preamble*root[2][3][1].value*" [description = \"TIME_STEP, the dt of the model\"]
@variables t_plus(t) = TIME_STEP/2 [description= \"t_plus, variable used for pulse to avoid rounding errors\"]\n"
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

"
eqs = [
    t_plus ~ t + (TIME_STEP / 2)
"
    for str in _decl_eqns 
        base_str= base_str *str
    end
    base_str = base_str *file_stop*root[2][1][1].value*","*root[2][2][1].value*"), solver="*method*", dt"*dt*", dtmax"*dt*")
solved=solve(prob)
    "
end



"""
  This function generate the String of the ModelingToolkit model translated from julia. One just need to paste it into a blank file to make it work. 
    it works like this: using the XML.jl module, it parse the input xml (or xmile) file found at "filepath" into a tree; then, it seperate this tree into 4 sections: 
        -the variables that will be derived in the model, those need initial values
        -the variables used in the model that will not be derived (except those containing a "smooth" function) and their equations
        -the tables (section necessary for information separation, if the model contain no table, it is necessary to add one, that can be blank)
        -and the parameters, along with their values. 

    after this, the equations are changed from Vensim to ModelingToolkit syntax; and then the string is constructed. 
"""
function file_generation(filepath::String="C:\\Users\\maelc\\OneDrive\\Documents\\stage\\New_parser_vensim_julia\\exemples\\community corona 8.xmile")

    filename,doc,root,len=setup(filepath)    
    (stocks_ind,eqn_ind,tables_ind,params_ind)=ind(root[3][1])  
    _params = Dict{Symbol,Float64}()
    getparameters() = copy(_params)
    add_parameters!(root[3][1],params_ind,len,_params)   
    _inits = Dict{Symbol,String}() 
    getinitialisations()= copy(_inits) 
    _decl_vars=Vector{String}()
    _decl_eqns=Vector{String}() 
    _tables = Dict{Symbol,Tuple{Vararg{Float64}}}()
    _ranges = Dict{Symbol,Tuple{Vararg{Float64}}}()
    add_inits!(root[3][1],stocks_ind,_inits,_decl_eqns,_decl_vars,_tables,_params)   
    table_maker(eqn_ind,tables_ind,root,_tables,_ranges)
    eqn_decls(stocks_ind, eqn_ind, root,_decl_eqns,_decl_vars,_tables)
    return (file_writer(_params,_inits,_tables,_ranges,_decl_vars,_decl_eqns,root))
end

function vensim2MTK(filepath::String=".\\examples\\lokta.xmile",filename::String="Defaultstring"
    ,overwrite::Bool=false)
    if filename == "Defaultstring"
        filename = splitext(basename(filepath))[1] * ".jl"
    end
    newfilepath =abspath("filename")
    isfile(newfilepath) && !overwrite && return (print("File:"*filename*"already exist. please use another name for the file or use the option \"true\" for the \"overwrite\" argument"))
    filedata=file_generation(filepath)
    file = open(filename,"w")
    write(file,filedata)
    close(file)
end
