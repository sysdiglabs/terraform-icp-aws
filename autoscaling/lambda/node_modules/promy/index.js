module.exports = function (fn){
    return function(obj, cb){
        if(cb && cb instanceof Function){
            fn(obj, cb);
        } else {
            return new Promise((resolve, reject)=>{
                fn(obj, (err, res)=>{
                    if(err){
                        reject(err);
                    } else {
                        resolve(res);
                    }
                });
            })
        }
    }
}