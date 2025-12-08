# Base image - official wso2 mi
FROM wso2/wso2mi:4.4.0

# Set working directory to where WSO2 deploys CAR files
WORKDIR /home/wso2carbon/wso2mi-4.4.0/repository/deployment/server/carbonapps/

# Deploy Project Integration
COPY ./AppointmentServices_1.0.0.car ./

# OPEN API Port - Expose API and management ports
EXPOSE 8290 8253

# Start the server automatically
CMD ["/home/wso2carbon/wso2mi-4.4.0/bin/micro-integrator.sh"]
