
module.exports = {
networks: {
    kovan:{
      network_id:42,
      gas: 4700000
    },
    test: {
      network_id: 424242,
      host: 'localhost',
      port: 8545,
      gas: 4700000
    },
  },
  migrations_directory: './migrations'
}
