// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

//Case reject - finally()
class ManyResolveRejectFin extends ImpTestCase {
    middleOfRand = 1.0 * RAND_MAX / 2;

    function _verifyTrue(condition, result, addMsg) {
        if (!condition) {
            result[1] = addMsg + result[1];
            result[0] = false;
        }
    }

    // Wrapper of Perform a deep comparison of two values
    // Useful for comparing arrays or tables
    // @param {*} expected
    // @param {*} actual
    // @param {string} message
    // @private
    function _assertDeepEqualWrap(expected, actual, message) {
        try {
            assertDeepEqual(expected, actual, message);
            return true;
        } catch (err) {
            server.log(err);
            return false;
        }
    }

    function _manyResolvingRejecting(isDelyed, values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                Promise(function(ok, err) {
                    // State mask
                    // 1 - resolve handler is called
                    // 2 - value is wrong in resolve handler
                    // 4 - reject handler is called
                    // 8 - value is wrong in reject handler
                    // 16 - fail handler is called
                    // 32 - value is wrong in fail handler
                    // 64 - finally handler is called
                    // 128 - value is wrong in finally handlerx
                    local iState = 0;
                    local myValue = value;
                    local strChain = "";

                    local cb = function (resolve, reject) { // many resolve/reject call
                        foreach (nextValue in values) {
                            local rnd = math.rand();
                            if (middleOfRand < rnd) {
                                strChain += "1";
                                resolve(nextValue);
                            } else {
                                strChain += "0";
                                reject(nextValue);
                            }
                        }
                    }.bindenv(this);

                    local p = ::Promise(function (resolve, reject) {
                        if (isDelyed) { // delayed rejecting
                            imp.wakeup(0.1, function () {
                                reject(myValue);
                                cb(resolve, reject); // many resolve/reject call
                            }.bindenv(this));
                        } else { // basic rejecting
                            reject(myValue);
                            cb(resolve, reject); // many resolve/reject call
                        }
                    }.bindenv(this));
                    p.finally(function(res) {
                        iState = iState | 64; // 64 - finally handler is called
                        if (_assertDeepEqualWrap(myValue, res, "Finally handler - wrong value, value=" + res)) {
                            iState = iState | 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this));

                    // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
                    assertEqual(0, iState, "The Promise should not be resolved strict after the promise declaration");

                    // now it should be resolved
                    imp.wakeup(1, function() {
                        local result = [true, "Value='" + myValue + "', iState=" + iState+", RND=" + strChain];
                        _verifyTrue(iState & 64, result, "Finally handler is not called. ");
                        _verifyTrue(iState & 128, result, "Value is wrong in finally handler. ");
                        if (iState & 0X3F) { // 0011 1111 = 0X3F
                            err("Failed: unexpected handler call. " + result[1]);
                        } else if (result[0]) {
                            ok("Passed: " + result[1]);
                        } else {
                            err("Failed: " + result[1]);
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
         return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    // Test rejection with many resolve/reject call

     function testBasicRejection_1() {
        return _manyResolvingRejecting(false, [true, false]);
    }

    function testBasicRejection_2() {
        return _manyResolvingRejecting(false, [0, 1]);
    }

    function testBasicRejection_3() {
        return _manyResolvingRejecting(false, [-1, ""]);
    }

    function testBasicRejection_4() {
        return _manyResolvingRejecting(false, ["tmp", 0.001]);
    }

    function testBasicRejection_5() {
        return _manyResolvingRejecting(false, [0.0, -0.001]);
    }

    function testBasicRejection_6() {
        return _manyResolvingRejecting(false, [regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testBasicRejection_7() {
        return _manyResolvingRejecting(false, [blob(4), array(5)]);
    }

    function testBasicRejection_8() {
        return _manyResolvingRejecting(false, [{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testBasicRejection_9() {
        return _manyResolvingRejecting(false, [class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }

    // Test delayed rejection with many resolve/reject call
    
    function testDelayedRejection_1() {
        return _manyResolvingRejecting(true, [true, false]);
    }

    function testDelayedRejection_2() {
        return _manyResolvingRejecting(true, [0, 1]);
    }

    function testDelayedRejection_3() {
        return _manyResolvingRejecting(true, [-1, ""]);
    }

    function testDelayedRejection_4() {
        return _manyResolvingRejecting(true, ["tmp", 0.001]);
    }

    function testDelayedRejection_5() {
        return _manyResolvingRejecting(true, [0.0, -0.001]);
    }

    function testDelayedRejection_6() {
        return _manyResolvingRejecting(true, [regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testDelayedRejection_7() {
        return _manyResolvingRejecting(true, [blob(4), array(5)]);
    }

    function testDelayedRejection_8() {
        return _manyResolvingRejecting(true, [{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testDelayedRejection_9() {
        return _manyResolvingRejecting(true, [class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }
}
