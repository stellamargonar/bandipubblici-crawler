module.exports = {

	"database" : {
		"host" : "localhost",
		"dbName" : "bandipubblici_dev"
	},
	"amqp" :{
		"config" : {
			"host" : "localhost",
			"port" : 5672
		},
		"queue" : {
			"crawler" : "crawler_queue",
			"extractor" : "extractor_queue",
			"saveCall" : "save_call_queue",
			"test" : "test_queue"
		
		}
	}
};