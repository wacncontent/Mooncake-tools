# encoding: utf-8

import time
import json
import multiprocessing as mp
from urlparse import urlparse
import requests
import urllib2
from bs4 import BeautifulSoup


class StatusCode(object):
    """ Status code of response"""
    # Return OK
    OK = 200
    # 404
    MoonCake_Not_Found = 404
    # 500
    MoonCake_Internal_Server_Error = 500


class SiteReader(object):
    """ Read site list from file """
    def __init__(self, filePath):
        self.filePath = filePath
        self.siteList = []

    def getSiteList(self):
        with open(self.filePath, 'r') as sites:
            for line in sites.readlines():
                self.siteList.append(line.strip())
        return self.siteList


class CheckRule(object):
    """ Check specified url """
    out_list = ['windowsazure.com', 'portal.azure.com', '.com/library', 'windows.net']

    def __init__(self, url):
        self.url = url

    def startCheck(self):
        try:
            for key in self.out_list:
                if key in self.url:
                    return 600
                    
            response = requests.get(self.url)

            # 1. check for real 404,500 etc
            if response.status_code == StatusCode.OK:
                # 2. check for mooncake 404 or 500 by check redirected url
                if response.url.find('errors/404') > 0:
                    return StatusCode.MoonCake_Not_Found
                elif response.url.find('errors/500') > 0:
                    return StatusCode.MoonCake_Internal_Server_Error
                else:
                    return StatusCode.OK
            else:
                return response.status_code
        except Exception as e:
            return StatusCode.MoonCake_Not_Found


class Checker(object):
    def __init__(self, url):
        # self.urlList = urlList
        self.startStr = '<div class="single-page">'
        self.endStr = '<footer class="footer">'
        self.url = url
        self.json_flag = False
        if self.url.endswith('.json'):
            self.host = 'http://azure.cn'
            self.json_flag = True
        else:
            # wacn host
            parsed_uri = urlparse(url)
            self.host = '{uri.scheme}://{uri.netloc}'.format(uri=parsed_uri)
        # url that has been proved good :)
        self.goodSet = set()
        # url that has been proved bad :(
        self.badSet = set()

    def check(self):
        # bad result
        badResult = '#### {0}\n'.format(self.url)
        badResult += '| Name | Link | State |\n'
        badResult += '| ---- | ---- | ----- |\n'

        # flag to indicate if error found
        error_flag = False
        # check for the url given
        firstResult = self.getCheckResult(self.url, 'Parent Link Error')
        # parent url error
        if not firstResult[0]:
            badResult = badResult + firstResult[1]
            error_flag = True
        else:
            # open parent url to get page content
            html = urllib2.urlopen(self.url).read()

            # extract our content between '<section class="wa-section">...</section>'
            siteDict = self.json_parser(html) if self.json_flag else self.parser(html)

            # Now we got site dictionary in ('url','text'), let's check
            for k, v in siteDict.iteritems():
                # Inner page link
                result = self.getCheckResult(k, v)
                if not result[0]:
                    error_flag = True
                    badResult = badResult + result[1]

        if not error_flag:
            badResult = ''
        return badResult

    def parser(self, html):
        # define temp dict to hold site dictionary
        tempDict = {}
        # extract our content between '<section class="wa-section">...</section>'
        startPos = html.index(self.startStr)
        endPos = html.index(self.endStr, startPos)
        content = html[startPos:endPos]

        soup = BeautifulSoup(content, "html.parser")
        for link in soup.find_all("a"):
            if not link.contents:
                continue
            href = link.get("href")
            if href is not None:
                # inner link and video link should be skipped
                if href.strip().startswith('#') or \
                        href.strip().startswith('//video') or \
                        href.strip().startswith('mailto:'):
                    continue
                # relative link
                if href.strip().startswith('/'):
                    href = self.host + href
                tempDict[href] = link.contents[0]

        return tempDict


    def json_parser(self, json_html):
        tempDict = {}
        bd = json.loads(json_html)
        nav = bd["navigation"]

        for section in nav:
            articles = section["articles"]
            for article in articles:
                link = article["link"]
                title = article["title"]
                if link.startswith('/'):
                    link = self.host + link

                tempDict[link] = title

        return tempDict

    def getCheckResult(self, url, name):
        # CheckResult flag
        flag = True
        status = 200
        # Check result string
        result = '| {0} | {1} | {2} |\n'
        # Check if the url is already in our goodSites or badSites
        if url in self.badSet:
            flag = False
            # proved to be bad url before
            status = 600
        if url not in self.goodSet:
            # New url
            rule = CheckRule(url)
            status = rule.startCheck()
            # if status good, add to goodSet
            if status == StatusCode.OK:
                self.goodSet.add(url)
            else:
                flag = False
                self.badSet.add(url)

        return flag, result.format(name.encode('utf-8'), url.encode('utf-8'), status)


def worker(arg, q):
    ''' worker '''
    try:
        checker = Checker(arg)
        result = checker.check()
        return result
    except KeyboardInterrupt:
        print('Cleanup in workers...')
        return 'kill'


def listener(q):
    ''' listen for messages on the q, writes to file. '''
    bad_file = open('bad.md', 'wb')

    while True:
        try:
            m = q.get()
            if m == 'kill':
                break
            else:
                bad_file.write(m)
        except KeyboardInterrupt:
            print('Receving keyboard interruption, exiting...')
            bad_file.close()

    bad_file.close()


if __name__ == '__main__':
    start = time.clock()
    print('Start time :{0}'.format(start))

    count = 0
    # Use manager queue
    manager = mp.Manager()
    q = manager.Queue()
    pool = mp.Pool(200)

    # put listener to work first
    watcher = pool.apply_async(listener, (q,))

    myReader = SiteReader('site.txt')
    siteList = myReader.getSiteList()
    total_count = len(siteList)

    # fire up workers
    jobs = []
    for url in siteList:
        job = pool.apply_async(worker, (url, q))
        jobs.append(job)

    # collect results from the workers throught the pool result queue
    try:
        for job in jobs:
            q.put(job.get())
            count = count + 1
        # now we are done, kill the listener
        q.put('kill')
        pool.close()
    except KeyboardInterrupt:
        print('Wait for worker to cleanup...')

    if total_count == count:
        print ('All Scanning OK')
    else:
        print ('Not all scanned, error occured!')

    print ('Total time : {0}'.format(time.clock() - start))