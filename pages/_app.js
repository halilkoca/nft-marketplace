import '../styles/globals.css'
import Link from 'next/link'

function KryptoBirdMarketplace({ Component, pageProps }) {
  return (
    <div>
      <nav className='border-b p-6' style={{ backgorundColor: 'purple' }}>
        <p className='text-4x1 font-bold text-white'>KryptoBird Marketplace</p>
        <div className='flex mt-4 justify-center'>
          <Link href='/'>
            <a className='mr-4'>Main Marketplace</a>
          </Link>
          <Link href='/mint-item'>
            <a className='mr-4'>Mint Tokens</a>
          </Link>
          <Link href='/my-nfts'>
            <a className='mr-4'>My NFTs</a>
          </Link>
          <Link href='/accout-dashboard'>
            <a className='mr-4'>Account Dashboard</a>
          </Link>
          <Component {...pageProps} />
        </div>
      </nav>
    </div>
  )
}

export default KryptoBirdMarketplace;