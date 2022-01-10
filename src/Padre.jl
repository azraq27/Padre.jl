module Padre

using JSON

export Subject,Session,Dataset

export padre_subjects
export subj_dir,tags,labels,sessions
export sess_dir,dsets,filename

## Config

padre_dir = ENV["PADRE_ROOT"]
subj_dir(subjid::String) = "$padre_dir/Data/$subjid"
json_file(subjid::String) = "$(subj_dir(subjid))/$subjid.json"

## Objects

mutable struct Subject
    subjid::String
    json::Dict
end

struct Session
    subj::Subject
    session::String
end

mutable struct Dataset
    filename::String
    meta::Dict
    sess::Session
end

import Base.show
function show(io::IO,s::Subject)
    write(io,"Subject(\"$(s.subjid)\")")
    return nothing
end

## Global functions

"""
    padre_subjects()

Return list of all available subjects as `Subject` objects."""
function padre_subjects()
    subjs = Subject[]
    
    for s in readdir(joinpath(padre_dir,"Data"))
        try
            subj = Subject(s)
            push!(subjs,subj)
        catch
        end
    end
    subjs
end
    

## Make a Subject

Subject(subjid::String) = Subject(subjid,JSON.parsefile(json_file(subjid)))

## Access functions

sess_dict(sess::Session) = sess.subj.json["sessions"][sess.session]
function tags(sess::Session)
    sd = sess_dict(sess)
    return haskey(sd,"tags") ? sd["tags"] : []
end
function labels(sess::Session)
    sd = sess_dict(sess)
    return haskey(sd,"labels") ? sd["labels"] : []
end

function sessions(s::Subject;tag=nothing,label=nothing,include::Bool=true)
    ss = Session[]
    for session in keys(s.json["sessions"])
        if (include == false) || (haskey(s.json["sessions"][session],"include") && s.json["sessions"][session]["include"])
            push!(ss,Session(s,session))
        end
    end
    tag != nothing && (ss = filter(x->tag in tags(x),ss))
    label != nothing && (ss = filter(x->label in labels(x),ss))
    return ss
end

function dsets(sess::Session,label::String;complete::Bool=true)
    ds = Dataset[]
    sd = sess_dict(sess)["labels"]
    haskey(sd,label) || return Dataset[]
    for x in sd[label]
        if (! complete) || x["complete"]
            push!(ds,Dataset(x["filename"],x["meta"],sess))
        end
    end
    return ds
end

function dsets(subj::Subject,label::String;complete::Bool=true,tag=nothing)
    ds = Dataset[]
    for sess in sessions(subj;tag)
        sd = sess_dict(sess)["labels"]
        haskey(sd,label) || return Dataset[]
        for x in sd[label]
            if (! complete) || x["complete"]
                push!(ds,Dataset(x["filename"],x["meta"],sess))
            end
        end
    end
    return ds
end

sess_dir(sess::Session) = "$(subj_dir(sess.subj.subjid))/sessions/$(sess.session)"
filename(dset::Dataset) = "$(sess_dir(dset.sess))/$(dset.filename)"

end # module
