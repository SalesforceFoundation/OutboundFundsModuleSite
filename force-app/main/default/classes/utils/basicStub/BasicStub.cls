@IsTest
public with sharing class BasicStub implements System.StubProvider {
    private Map<String, List<MethodCall>> methodCallsByMethodKey = new Map<String, List<MethodCall>>();
    private Map<String, List<Id>> idsByMethodKey = new Map<String, List<Id>>();
    private Map<String, Id> idByMethodKey = new Map<String, Id>();
    private Map<String, Object> returnValueByMethodKey = new Map<String, Object>();
    private Map<String, Exception> methodCallsToThrowException = new Map<String, Exception>();
    private Type objType;
    public String testExceptionMessage = 'Exception thrown by Basic Stub.';

    public BasicStub(Type objType) {
        this.objType = objType;
    }

    public Object handleMethodCall(
        Object obj,
        String methodName,
        Type returnType,
        List<Type> paramTypes,
        List<String> paramNames,
        List<Object> args
    ) {
        MethodCall methodCall = new MethodCall(
            obj,
            methodName,
            returnType,
            paramTypes,
            args
        );

        return process(methodCall);
    }

    public BasicStub withSetRecordId(String methodName, Type paramType, Id idToUse) {
        idByMethodKey.put(
            createMethodKey(methodName, new List<Type>{ paramType }),
            idToUse
        );
        return this;
    }

    /* When a domain class is called with a list of sObjects, BasicStub will assign the Ids provided in order
     * Only supports a domain method with a single argument, which is best practice anyway. */
    public BasicStub withSetRecordIds(
        String methodName,
        Type paramType,
        List<Id> idsToUse
    ) {
        idsByMethodKey.put(
            createMethodKey(methodName, new List<Type>{ paramType }),
            idsToUse
        );
        return this;
    }

    public BasicStub withThrowException(String methodName) {
        return this.withThrowException(methodName, new List<Type>());
    }

    public BasicStub withThrowException(String methodName, Type paramType) {
        return this.withThrowException(methodName, new List<Type>{ paramType });
    }

    public BasicStub withThrowException(String methodName, List<Type> paramTypes) {
        return this.withThrowException(methodName, paramTypes, (Exception) null);
    }

    public BasicStub withThrowException(
        String methodName,
        List<Type> paramTypes,
        Exception exceptionToThrow
    ) {
        this.methodCallsToThrowException.put(
            createMethodKey(methodName, paramTypes),
            exceptionToThrow
        );
        return this;
    }

    public BasicStub withReturnValue(String methodName, Object returnValue) {
        return withReturnValue(methodName, new List<Type>(), returnValue);
    }

    public BasicStub withReturnValue(
        String methodName,
        Type paramType,
        Object returnValue
    ) {
        return withReturnValue(methodName, new List<Type>{ paramType }, returnValue);
    }

    public BasicStub withReturnValue(
        String methodName,
        List<Type> paramTypes,
        Object returnValue
    ) {
        returnValueByMethodKey.put(createMethodKey(methodName, paramTypes), returnValue);

        return this;
    }

    private String createMethodKey(String methodName, List<Type> paramTypes) {
        return new MethodCall().createMethodKey(methodName, paramTypes);
    }

    public Object process(MethodCall methodCall) {
        record(methodCall);

        if (idsByMethodKey.containsKey(methodCall.getMethodKey())) {
            List<Object> args = methodCall.getArgObjects();
            List<SObject> sObjects = (List<SObject>) args[0];
            List<Id> ids = idsByMethodKey.get(methodCall.getMethodKey());
            for (Integer i = 0; i < sObjects.size(); i++) {
                sObjects[i].Id = ids[i];
            }
        }

        if (idByMethodKey.containsKey(methodCall.getMethodKey())) {
            Id id = idByMethodKey.get(methodCall.getMethodKey());
            ((SObject) methodCall.getArgObjects()[0]).Id = id;
        }

        if (methodCallsToThrowException.containsKey(methodCall.getMethodKey())) {
            Exception e = methodCallsToThrowException.get(methodCall.getMethodKey());
            if (e == null) {
                e = new StubException(this.testExceptionMessage);
            }
            throw e;
        }

        if (returnValueByMethodKey.containsKey(methodCall.getMethodKey())) {
            return returnValueByMethodKey.get(methodCall.getMethodKey());
        }

        if (methodCall.returnType == objType) {
            return methodCall.getObject();
        }

        return null;
    }

    public void record(MethodCall methodCall) {
        isValid(methodCall);

        List<MethodCall> methodCalls = methodCallsByMethodKey.get(
            methodCall.getMethodKey()
        );
        if (methodCalls == null) {
            methodCalls = new List<MethodCall>();
        }

        methodCalls.add(methodCall);
        methodCallsByMethodKey.put(methodCall.getMethodKey(), methodCalls);
    }

    public Object createMock() {
        return Test.createStub(objType, this);
    }

    private void isValid(MethodCall methodCall) {
        String methodCallObjectName = extractObjectName(
            String.valueOf(methodCall.getObject())
        );
        String stubbedObjectName = removeNamespace(objType.getName());

        System.assertEquals(
            stubbedObjectName,
            methodCallObjectName,
            'The method that was called is from another class, ' +
            methodCallObjectName +
            '.'
        );
    }

    private String extractObjectName(String methodCallObject) {
        return methodCallObject.split(':')[0].removeEnd('__sfdc_ApexStub');
    }

    private String removeNamespace(String name) {
        String namespaceRemoved = name.substringAfter('.');

        return String.isBlank(namespaceRemoved) ? name : namespaceRemoved;
    }

    public void assertCalled(String methodName) {
        assertCalled(methodName, new List<Type>());
    }

    public void assertCalled(String methodName, Type paramType) {
        assertCalled(methodName, new List<Type>{ paramType });
    }

    public void assertCalled(String methodName, List<Type> paramTypes) {
        String methodKey = createMethodKey(methodName, paramTypes);

        System.assert(
            methodCallsByMethodKey.containsKey(methodKey),
            methodKey +
            ' was not called as expected. - ' +
            methodCallsByMethodKey.keySet()
        );
    }

    public void assertNotCalled(String methodName) {
        assertNotCalled(methodName, new List<Type>());
    }

    public void assertNotCalled(String methodName, Type paramType) {
        assertNotCalled(methodName, new List<Type>{ paramType });
    }

    public void assertNotCalled(String methodName, List<Type> paramTypes) {
        String methodKey = createMethodKey(methodName, paramTypes);

        System.assert(
            !methodCallsByMethodKey.containsKey(methodKey),
            methodKey +
            ' was not expected to have been called. - ' +
            methodCallsByMethodKey.keySet()
        );
    }

    public void assertCalledWith(String methodName, Type paramType, Object arg) {
        assertCalledWith(
            methodName,
            new List<Type>{ paramType },
            new List<Object>{ arg }
        );
    }

    public void assertCalledWith(
        String methodName,
        List<Type> paramTypes,
        List<Object> args
    ) {
        String methodKey = createMethodKey(methodName, paramTypes);

        assertCalled(methodName, paramTypes);
        Boolean matchFound = false;
        List<MethodCall> methodCalls = methodCallsByMethodKey.get(methodKey);

        for (MethodCall methodCall : methodCalls) {
            for (Object arg : args) {
                matchFound = methodCall.getArgs().contains(String.valueOf(arg));
                if (!matchFound) {
                    break; // All args must be found within the same method
                }
            }

            if (matchFound) {
                break; // All args were matched no need to proceed
            }
        }

        System.assert(
            matchFound,
            'The expected argument(s), ' +
            args +
            ', was not found. - ' +
            methodCalls
        );
    }

    private class MethodCall {
        private Object obj;
        private String methodName;
        private Type returnType;
        private List<Type> paramTypes;
        private List<Object> argObjects;
        private List<String> args;
        private String key;

        private MethodCall() {
        }

        private MethodCall(
            Object obj,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<Object> args
        ) {
            this.obj = obj;
            this.methodName = methodName;
            this.returnType = returnType;
            this.paramTypes = paramTypes;
            this.argObjects = args;

            this.args = new List<String>();
            for (Object arg : args) {
                this.args.add(String.valueOf(arg));
            }
        }

        private List<Object> getArgObjects() {
            return argObjects;
        }

        private List<String> getArgs() {
            return args;
        }

        private Object getObject() {
            return obj;
        }

        private String getMethodKey() {
            if (key != null) {
                return key;
            }

            key = createMethodKey(String.valueOf(methodName), paramTypes);

            return key;
        }

        private String createMethodKey(String methodName, List<Type> paramTypes) {
            String format = '{0}:{1}';

            return String.format(
                format,
                new List<String>{ methodName, String.valueOf(paramTypes) }
            );
        }
    }

    private class StubException extends Exception {
    }
}
