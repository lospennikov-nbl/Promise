/// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

class Serial extends ImpTestCase {
    
    function _wrongType(values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local myValue = value;
                    local msg = "with value='" + myValue + "'";
                    local _value = null;
                    try {
                        ::Promise.serial(myValue).then(function(res) { 
                            msg = "Resolve handler is called " + msg;
                        }.bindenv(this), function(res) { 
                            _value = res;
                        }.bindenv(this));
                    } catch(ex) {
                        msg = "Unexpected error " + ex + " " + msg;
                    }
                    imp.wakeup(1, function() {
                        if (_value == null) {
                            server.log("Fail " + msg);
                            err("Fail " + msg);
                        } else {
                            //server.log("Pass " + msg);
                            ok("Pass " + msg);
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    // Disabled
    // Issue: Unexpected error in Promise.serial() #24
    function _DISABLED_testWrongType_1() {
        return _wrongType([false, 0, "",  "tmp", 0.001]);
    }

    function _DISABLED_testWrongType_2() {
        return _wrongType([regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null, blob(4)]);
    }

    function _DISABLED_testWrongType_3() {
        return _wrongType([array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
        }]);
    }

    function _DISABLED_testWrongType_4() {
        return _wrongType([class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server]);
    }

    function testWrongCount() {
        local values = [false, 0, "", "tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server];
        foreach (value in values) {
            try {
                ::Promise.serial(value, value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }
}
