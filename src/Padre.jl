module Padre

using JSON

export Subject,Session,Dataset

export subj_dir,tags,labels,sessions
export sess_dir,dsets,filename

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

## Make a Subject

padre_dir = ENV["PADRE_ROOT"]
subj_dir(subjid::String) = "$padre_dir/Data/$subjid"
json_file(subjid::String) = "$(subj_dir(subjid))/$subjid.json"

Subject(subjid::String) = Subject(subjid,JSON.parsefile(json_file(subjid)))

## Access functions

sess_dict(sess::Session) = sess.subj.json["sessions"][sess.session]
tags(sess::Session) = sess_dict(sess)["tags"]
labels(sess::Session) = collect(keys(sess_dict(sess)["labels"]))

function sessions(s::Subject;tag=nothing,label=nothing)
    ss = [Session(s,session) for session in keys(s.json["sessions"])]
    tag != nothing && (ss = filter(x->tag in tags(x),ss))
    label != nothing && (ss = filter(x->label in labels(x),ss))
    return ss
end

dsets(sess::Session,label::String) = [Dataset(x["filename"],x["meta"],sess) for x in sess_dict(sess)["labels"][label]]
sess_dir(sess::Session) = "$(subj_dir(sess.subj.subjid))/sessions/$(sess.session)"
filename(dset::Dataset) = "$(sess_dir(dset.sess))/$(dset.filename)"

end # module
