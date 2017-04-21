module.exports = {
networks: {
    'staging': {
      network_id: 1337 // custom private network
      // use default rpc settings
    },
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 4700000
    }
  },
  migrations_directory: './migrations'
}
